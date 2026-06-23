# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only WITH Qt-GPL-exception-1.0

from __future__ import annotations

import re
from typing import Any, Dict, List, Tuple

from rosidl_parser.definition import (
    AbstractNestedType,
    AbstractString,
    AbstractWString,
    Array,
    BoundedSequence,
    NamespacedType,
    UnboundedSequence,
)

from . import (
    get_namespaced_type_mapping,
    get_qml_value_type_name,
    get_qt_class_name,
    get_qt_class_name_full,
    get_qt_namespace,
    msg_type_to_qt,
    msg_type_to_qt_full,
    msg_type_to_cpp,
    snake_to_camel,
    to_snake_case,
)


def get_qml_module_uri(package_name: str) -> str:
    """Compute the QML module URI for a ROS package (e.g. QtRos2.BuiltinInterfaces)."""
    return 'QtRos2.' + ''.join(w.capitalize() for w in package_name.split('_') if w)


# Per-field doc overrides for built-in message types whose .msg comments are
# missing or thin. Keys are "package/MessageName", values are dicts mapping
# field_name -> list of doc lines. First line becomes \brief; remaining lines
# form the property body. Use qdoc markup (\\l, \\c, \\sa, etc.); double the
# backslashes since these are Python strings.
_FIELD_DOC_OVERRIDES: Dict[str, Dict[str, List[str]]] = {
    "geometry_msgs/Wrench": {
        "force":  ["Linear force in newtons (N)."],
        "torque": ["Torque about each axis in newton-metres (N·m)."],
    },
    "geometry_msgs/Twist": {
        "linear":  ["Linear velocity in metres per second (m/s)."],
        "angular": ["Angular velocity in radians per second (rad/s)."],
    },
    "geometry_msgs/Accel": {
        "linear":  ["Linear acceleration in m/s²."],
        "angular": ["Angular acceleration in rad/s²."],
    },
    "geometry_msgs/Inertia": {
        "m":   ["Mass in kilograms (kg)."],
        "com": ["Position of the center of mass in metres (m)."],
        "ixx": ["Moment of inertia about the X axis in kg·m²."],
        "ixy": ["Product of inertia between the X and Y axes in kg·m²."],
        "ixz": ["Product of inertia between the X and Z axes in kg·m²."],
        "iyy": ["Moment of inertia about the Y axis in kg·m²."],
        "iyz": ["Product of inertia between the Y and Z axes in kg·m²."],
        "izz": ["Moment of inertia about the Z axis in kg·m²."],
    },
    "geometry_msgs/TwistWithCovariance": {
        "covariance": [
            "Row-major 6×6 covariance matrix for the \\l twist.",
            "Diagonal entries are variances of \\c {linear.x}, \\c {linear.y},",
            "\\c {linear.z}, \\c {angular.x}, \\c {angular.y}, \\c {angular.z}",
            "(in that order); off-diagonal entries are the corresponding",
            "covariances. Set all 36 entries; unknown components are often",
            "left at zero or filled with a small positive variance.",
        ],
    },
    "geometry_msgs/PoseWithCovariance": {
        "covariance": [
            "Row-major 6×6 covariance matrix for the \\l pose.",
            "Diagonal entries are variances of \\c {position.x}, \\c {position.y},",
            "\\c {position.z} and the fixed-axis rotations about X, Y, Z",
            "(in that order); off-diagonal entries are the corresponding",
            "covariances.",
        ],
    },
    "geometry_msgs/AccelWithCovariance": {
        "covariance": [
            "Row-major 6×6 covariance matrix for the \\l accel.",
            "Diagonal entries are variances of \\c {linear.x}, \\c {linear.y},",
            "\\c {linear.z}, \\c {angular.x}, \\c {angular.y}, \\c {angular.z}",
            "(in that order); off-diagonal entries are the corresponding",
            "covariances.",
        ],
    },
}


# Per-type brief override; replaces whatever rosidl_adapter mis-derives.
_VALUE_TYPE_BRIEF_OVERRIDE: Dict[str, str] = {
    "geometry_msgs/Inertia": "Rigid-body mass and inertia tensor about a center of mass.",
}


# Per-type qdoc paragraphs appended to the generated value-type description
# (not the publisher / subscriber). Keys are "package/MessageName".
# Each paragraph is a list of lines; consecutive paragraphs are joined with a
# blank line. Use \\l, \\c etc. for qdoc markup; double the backslashes.
_VALUE_TYPE_EXTRA_DOC: Dict[str, List[List[str]]] = {
    "geometry_msgs/Quaternion": [
        [
            "Similar to QtQuick's \\l {QtQuick::}{quaternion} value type but",
            "stored as four \\c double components (\\c x, \\c y, \\c z, \\c w)",
            "rather than \\c float, matching the ROS 2 wire format. Use",
            "\\l toQuaternion() / \\l fromQuaternion() to bridge to",
            "\\l QQuaternion when its math API (slerp, normalize, multiplication)",
            "is needed.",
        ],
        [
            "A literal value is a JavaScript object such as",
            "\\c {({ x: 0, y: 0, z: 0, w: 1 })} (\\c w defaults to \\c 1). The",
            "\\l {QtRos2.GeometryMsgs::}{Quaternion} helper's",
            "\\l {QtRos2.GeometryMsgs::Quaternion::}{fromEulerAngles} takes ROS",
            "roll/pitch/yaw (about X/Y/Z, Z-up) in degrees; do not use QtQuick3D's",
            "\\c Quaternion, whose argument order is pitch/yaw/roll in a Y-up frame,",
            "or the axes come out wrong when published to ROS.",
        ],
    ],
    "geometry_msgs/Vector3": [
        [
            "Similar to QtQuick's \\l {QtQuick::}{vector3d} value type but",
            "stored as three \\c double components, matching the ROS 2 wire",
            "format. Use \\l toVector3D() / \\l fromVector3D() to bridge to",
            "\\l QVector3D when its math API is needed.",
        ],
    ],
    "geometry_msgs/Point": [
        [
            "Semantically a 3D point rather than a free vector, but stored",
            "identically to \\l vector3 (three \\c double components). Use",
            "\\l toVector3D() / \\l fromVector3D() to bridge to \\l QVector3D.",
        ],
    ],
}


def value_type_extra_doc(package_name: str, message_spec) -> List[List[str]]:
    """Return per-type extra qdoc paragraphs to append to a value type's
    description, as a list of paragraphs (each a list of lines).
    """
    msg_name = message_spec.structure.namespaced_type.name
    return _VALUE_TYPE_EXTRA_DOC.get(f"{package_name}/{msg_name}", [])


def value_type_brief_override(package_name: str, message_spec) -> str:
    """If a hand-written brief is configured for this message, return it; else ''."""
    msg_name = message_spec.structure.namespaced_type.name
    return _VALUE_TYPE_BRIEF_OVERRIDE.get(f"{package_name}/{msg_name}", "")

NestedInclude = Tuple[str, str, bool]

# Computed (Qt-only) properties appended to field_infos for specific messages.
# cpp_impl_tmpl uses {ns}/{cls} as format placeholders; C++ braces are doubled.
_COMPUTED_PROPERTIES: Dict[str, List[Dict[str, Any]]] = {
    "sensor_msgs/CompressedImage": [
        {
            "is_computed": True,
            "name": "image",
            "qt_type": "QImage",
            "qt_prop_name": "image",
            "property_spec": "Q_PROPERTY(QImage image READ image WRITE setImage)",
            "getter_decl": "QImage image() const;",
            "setter_decl": "void setImage(const QImage& img);",
            "extra_includes": ["<QImage>"],
            "extra_cpp_includes": ["<QBuffer>"],
            "cpp_impl_tmpl": (
                "QImage {ns}::{cls}::image() const\n"
                "{{\n"
                "    return QImage::fromData(m_data);\n"
                "}}\n"
                "\n"
                "void {ns}::{cls}::setImage(const QImage& img)\n"
                "{{\n"
                "    const char* qtFmt = m_format.contains(QLatin1String(\"png\")) ? \"PNG\" : \"JPEG\";\n"
                "    m_data.clear();\n"
                "    QBuffer buf(&m_data);\n"
                "    buf.open(QIODevice::WriteOnly);\n"
                "    img.save(&buf, qtFmt);\n"
                "}}\n"
            ),
        }
    ],
    "sensor_msgs/Image": [
        {
            "is_computed": True,
            "name": "image",
            "qt_type": "QImage",
            "qt_prop_name": "image",
            "property_spec": "Q_PROPERTY(QImage image READ image)",
            "getter_decl": "QImage image() const;",
            "setter_decl": None,
            "extra_includes": ["<QImage>"],
            "extra_cpp_includes": [],
            "cpp_impl_tmpl": (
                "QImage {ns}::{cls}::image() const\n"
                "{{\n"
                "    if (m_data.isEmpty() || m_width == 0 || m_height == 0)\n"
                "        return {{}};\n"
                "    static const QHash<QString, QImage::Format> fmtMap = {{\n"
                "        {{ QStringLiteral(\"rgb8\"),   QImage::Format_RGB888     }},\n"
                "        {{ QStringLiteral(\"rgba8\"),  QImage::Format_RGBA8888   }},\n"
                "        {{ QStringLiteral(\"bgr8\"),   QImage::Format_BGR888     }},\n"
                "        {{ QStringLiteral(\"mono8\"),  QImage::Format_Grayscale8  }},\n"
                "        {{ QStringLiteral(\"mono16\"), QImage::Format_Grayscale16 }},\n"
                "    }};\n"
                "    const QImage::Format fmt = fmtMap.value(m_encoding, QImage::Format_Invalid);\n"
                "    if (fmt == QImage::Format_Invalid)\n"
                "        return {{}};\n"
                "    return QImage(reinterpret_cast<const uchar*>(m_data.constData()),\n"
                "                  static_cast<int>(m_width), static_cast<int>(m_height),\n"
                "                  static_cast<int>(m_step), fmt).copy();\n"
                "}}\n"
            ),
        }
    ],
    "geometry_msgs/Quaternion": [
        {
            # Degrees, as a QVector3D (Qt convention + Qt type) so it binds
            # directly to QtQuick3D's Node.eulerRotation. Derived from the
            # double-precision rpy() core below (single source of truth).
            "is_computed": True,
            "name": "eulerAngles",
            "qt_type": "QVector3D",
            "qt_prop_name": "eulerAngles",
            "qml_doc_type": "vector3d",
            "property_spec": "Q_PROPERTY(QVector3D eulerAngles READ eulerAngles WRITE setEulerAngles)",
            "getter_decl": "QVector3D eulerAngles() const;",
            "setter_decl": "void setEulerAngles(const QVector3D& eulerAngles);",
            "extra_decls": [
                "Q_INVOKABLE static {cls} fromEulerAngles(const QVector3D& eulerAngles);",
            ],
            "qml_methods": [
                {
                    "static_factory": True,
                    "signature": "{vt} {se}::fromEulerAngles(vector3d eulerAngles)",
                    "brief": "Construct a quaternion from Euler angles in degrees.",
                    "body": [
                        "Components are (\\c x = roll about X, \\c y = pitch about Y,",
                        "\\c z = yaw about Z), ROS axis convention. An overload",
                        "taking three \\c real arguments (\\c x, \\c y, \\c z) is also",
                        "available.",
                    ],
                },
            ],
            "extra_includes": ["<QVector3D>", "\"vector3.hpp\""],
            "extra_cpp_includes": ["<QQuaternion>"],
            "brief_doc": "Orientation as Euler angles in degrees, as a \\l vector3d.",
            "doc_lines": [
                "Components are (\\c x = roll about X, \\c y = pitch about Y,",
                "\\c z = yaw about Z) using the ROS Z-up axis convention. Single",
                "precision (\\l QVector3D), for direct binding to Qt Quick 3D's",
                "\\c eulerRotation.",
                "",
                "See \\l rpy for radians and \\l rpyDegrees for degrees as a",
                "double-precision \\l vector3 (usable without Qt Quick).",
            ],
            "cpp_impl_tmpl": (
                "QVector3D {ns}::{cls}::eulerAngles() const\n"
                "{{\n"
                "    const {ns}::Vector3 deg = rpyDegrees();\n"
                "    return QVector3D(static_cast<float>(deg.x()),\n"
                "                     static_cast<float>(deg.y()),\n"
                "                     static_cast<float>(deg.z()));\n"
                "}}\n"
                "\n"
                "void {ns}::{cls}::setEulerAngles(const QVector3D& eulerAngles)\n"
                "{{\n"
                "    const QQuaternion q =\n"
                "        QQuaternion::fromEulerAngles(eulerAngles.y(), eulerAngles.z(), eulerAngles.x());\n"
                "    m_x = q.x();\n"
                "    m_y = q.y();\n"
                "    m_z = q.z();\n"
                "    m_w = q.scalar();\n"
                "}}\n"
                "\n"
                "{ns}::{cls} {ns}::{cls}::fromEulerAngles(const QVector3D& eulerAngles)\n"
                "{{\n"
                "    {ns}::{cls} r;\n"
                "    r.setEulerAngles(eulerAngles);\n"
                "    return r;\n"
                "}}\n"
            ),
        },
        {
            # Radians, as a ROS vector3 (ROS convention + ROS type): double
            # precision, and usable from a QCoreApplication (no Qt Quick needed,
            # unlike QVector3D's vector3d value type). This is the double-precision
            # source of truth for the Euler decomposition; eulerAngles/rpyDegrees
            # derive from it.
            "is_computed": True,
            "name": "rpy",
            "qt_type": "Qtros2GeometryMsgs::Vector3",
            "qt_prop_name": "rpy",
            "qml_doc_type": "vector3",
            "property_spec": "Q_PROPERTY(Qtros2GeometryMsgs::Vector3 rpy READ rpy WRITE setRpy)",
            "getter_decl": "Qtros2GeometryMsgs::Vector3 rpy() const;",
            "setter_decl": "void setRpy(const Qtros2GeometryMsgs::Vector3& rpy);",
            "extra_decls": [
                "Q_INVOKABLE static {cls} fromRpy(const Qtros2GeometryMsgs::Vector3& rpy);",
            ],
            "qml_methods": [
                {
                    "static_factory": True,
                    "signature": "{vt} {se}::fromRpy(vector3 rpy)",
                    "brief": "Construct a quaternion from roll/pitch/yaw in radians.",
                    "body": [
                        "Equivalent to \\l fromEulerAngles but in radians.",
                    ],
                },
            ],
            "extra_includes": [],
            "extra_cpp_includes": ["<QtMath>", "<cmath>"],
            "brief_doc": "Orientation as roll/pitch/yaw in radians (ROS convention).",
            "doc_lines": [
                "Components are (\\c x = roll, \\c y = pitch, \\c z = yaw) in radians,",
                "as a double-precision \\l vector3. This is the ROS-native form and,",
                "unlike \\l eulerAngles, is usable from a \\c QCoreApplication (it does",
                "not need the Qt Quick \\c vector3d value type).",
                "",
                "Precision may still degrade near gimbal singularities (pitch = ±90°).",
            ],
            "cpp_impl_tmpl": (
                "{ns}::Vector3 {ns}::{cls}::rpy() const\n"
                "{{\n"
                "    // Double-precision quaternion -> (roll, pitch, yaw) in radians,\n"
                "    // matching QQuaternion::toEulerAngles()'s convention (ROS axes:\n"
                "    // x = roll about X, y = pitch about Y, z = yaw about Z).\n"
                "    const double len = std::sqrt(m_x * m_x + m_y * m_y + m_z * m_z + m_w * m_w);\n"
                "    const bool rescale = !qFuzzyIsNull(len);\n"
                "    const double x = rescale ? m_x / len : m_x;\n"
                "    const double y = rescale ? m_y / len : m_y;\n"
                "    const double z = rescale ? m_z / len : m_z;\n"
                "    const double w = rescale ? m_w / len : m_w;\n"
                "    const double xx = x * x, xy = x * y, xz = x * z, xw = x * w;\n"
                "    const double yy = y * y, yz = y * z, yw = y * w;\n"
                "    const double zz = z * z, zw = z * w;\n"
                "    constexpr double epsilon = 1e-12;\n"
                "    double roll, pitch, yaw;\n"
                "    const double sinp = -2.0 * (yz - xw);\n"
                "    if (std::abs(sinp) < 1.0 - epsilon) {{\n"
                "        pitch = std::asin(sinp);\n"
                "        yaw = std::atan2(2.0 * (xz + yw), 1.0 - 2.0 * (xx + yy));\n"
                "        roll = std::atan2(2.0 * (xy + zw), 1.0 - 2.0 * (xx + zz));\n"
                "    }} else {{\n"
                "        // Gimbal lock: no unique solution; use XY rotation.\n"
                "        pitch = std::copysign(M_PI / 2.0, sinp);\n"
                "        yaw = 2.0 * std::atan2(y, w);\n"
                "        roll = 0.0;\n"
                "    }}\n"
                "    {ns}::Vector3 r;\n"
                "    r.setX(roll);\n"
                "    r.setY(pitch);\n"
                "    r.setZ(yaw);\n"
                "    return r;\n"
                "}}\n"
                "\n"
                "void {ns}::{cls}::setRpy(const {ns}::Vector3& rpy)\n"
                "{{\n"
                "    setEulerAngles(QVector3D(static_cast<float>(qRadiansToDegrees(rpy.x())),\n"
                "                             static_cast<float>(qRadiansToDegrees(rpy.y())),\n"
                "                             static_cast<float>(qRadiansToDegrees(rpy.z()))));\n"
                "}}\n"
                "\n"
                "{ns}::{cls} {ns}::{cls}::fromRpy(const {ns}::Vector3& rpy)\n"
                "{{\n"
                "    {ns}::{cls} r;\n"
                "    r.setRpy(rpy);\n"
                "    return r;\n"
                "}}\n"
            ),
        },
        {
            # Degrees, as a ROS vector3: double precision and usable without Qt
            # Quick (e.g. a headless QCoreApplication daemon whose motor controller
            # works in degrees). Read-only; construct via fromEulerAngles.
            "is_computed": True,
            "name": "rpyDegrees",
            "qt_type": "Qtros2GeometryMsgs::Vector3",
            "qt_prop_name": "rpyDegrees",
            "qml_doc_type": "vector3",
            "property_spec": "Q_PROPERTY(Qtros2GeometryMsgs::Vector3 rpyDegrees READ rpyDegrees)",
            "getter_decl": "Qtros2GeometryMsgs::Vector3 rpyDegrees() const;",
            "setter_decl": None,
            "extra_includes": [],
            "extra_cpp_includes": ["<QtMath>"],
            "brief_doc": "Orientation as roll/pitch/yaw in degrees, as a \\l vector3.",
            "doc_lines": [
                "Components are (\\c x = roll, \\c y = pitch, \\c z = yaw) in degrees,",
                "as a double-precision \\l vector3. Like \\l rpy (and unlike",
                "\\l eulerAngles) it is usable without Qt Quick — convenient for a",
                "headless \\c QCoreApplication consumer that works in degrees.",
            ],
            "cpp_impl_tmpl": (
                "{ns}::Vector3 {ns}::{cls}::rpyDegrees() const\n"
                "{{\n"
                "    const {ns}::Vector3 rad = rpy();\n"
                "    {ns}::Vector3 r;\n"
                "    r.setX(qRadiansToDegrees(rad.x()));\n"
                "    r.setY(qRadiansToDegrees(rad.y()));\n"
                "    r.setZ(qRadiansToDegrees(rad.z()));\n"
                "    return r;\n"
                "}}\n"
            ),
        },
        {
            "is_computed": True,
            "name": "qquaternionBridges",
            "property_spec": None,
            "getter_decl": None,
            "setter_decl": None,
            "extra_decls": [
                "Q_INVOKABLE QQuaternion toQuaternion() const;",
                "Q_INVOKABLE static {cls} fromQuaternion(const QQuaternion& q);",
            ],
            "qml_methods": [
                {
                    "signature": "QQuaternion {vt}::toQuaternion()",
                    "brief": "Return a single-precision \\l QQuaternion with the same orientation.",
                    "body": [
                        "Useful for accessing \\l QQuaternion's math API",
                        "(slerp, normalize, multiplication).",
                    ],
                },
                {
                    "static_factory": True,
                    "signature": "{vt} {se}::fromQuaternion(QQuaternion q)",
                    "brief": "Construct a quaternion from a \\l QQuaternion.",
                },
            ],
            "extra_includes": ["<QQuaternion>"],
            "extra_cpp_includes": [],
            "cpp_impl_tmpl": (
                "QQuaternion {ns}::{cls}::toQuaternion() const\n"
                "{{\n"
                "    return QQuaternion(static_cast<float>(m_w),\n"
                "                       static_cast<float>(m_x),\n"
                "                       static_cast<float>(m_y),\n"
                "                       static_cast<float>(m_z));\n"
                "}}\n"
                "\n"
                "{ns}::{cls} {ns}::{cls}::fromQuaternion(const QQuaternion& q)\n"
                "{{\n"
                "    {ns}::{cls} r;\n"
                "    r.m_x = q.x();\n"
                "    r.m_y = q.y();\n"
                "    r.m_z = q.z();\n"
                "    r.m_w = q.scalar();\n"
                "    return r;\n"
                "}}\n"
            ),
        },
        {
            # QML-invokable constructor from Qt's QQuaternion. QtQuick3D's
            # Quaternion.fromEulerAngles() (and QtQuick's quaternion type) produce
            # a QQuaternion whose real component is `scalar`, not `w`. When such a
            # value is assigned to a ROS quaternion property, QML looks for a
            # matching constructor; without this it finds none and rejects the
            # assignment. Providing it makes the (common) mix-up "just work",
            # mapping scalar -> w.
            "is_computed": True,
            "name": "qquaternionCtor",
            "property_spec": None,
            "getter_decl": None,
            "setter_decl": None,
            "extra_decls": [
                "Q_INVOKABLE {cls}(const QQuaternion& q);",
            ],
            "extra_includes": [],
            "extra_cpp_includes": [],
            "cpp_impl_tmpl": (
                "{ns}::{cls}::{cls}(const QQuaternion& q)\n"
                "    :\n"
                "      m_x(q.x()),\n"
                "      m_y(q.y()),\n"
                "      m_z(q.z()),\n"
                "      m_w(q.scalar())\n"
                "{{}}\n"
            ),
        },
        {
            # Alias of `w` matching QtQuick's quaternion value type (whose real
            # component is named "scalar", not "w"). When QtQuick is imported,
            # QQuaternion is a structured value type and QML converts it to this
            # type by property NAME — without a "scalar" property the real
            # component is dropped and w falls back to its default. This (the
            # name-population path) and the Q_INVOKABLE QQuaternion constructor
            # above (the constructor path, used when QtQuick is not imported) are
            # complementary; both are needed to robustly map scalar -> w. Reuses
            # the generated w()/setW(); not a stored member, not on the ROS wire.
            "is_computed": True,
            "name": "scalar",
            "qt_type": "double",
            "qt_prop_name": "scalar",
            "qml_doc_type": "double",
            "property_spec": "Q_PROPERTY(double scalar READ w WRITE setW)",
            "getter_decl": None,
            "setter_decl": None,
            "brief_doc": "The scalar (real) component; an alias of \\l w.",
            "doc_lines": [
                "Lets a QtQuick \\l {QtQuick::}{quaternion} assigned to this type",
                "map its \\c scalar onto \\c w (QML converts value types by name).",
            ],
        },
    ],
    "geometry_msgs/Vector3": [
        {
            "is_computed": True,
            "name": "qvector3dBridges",
            "property_spec": None,
            "getter_decl": None,
            "setter_decl": None,
            "extra_decls": [
                "Q_INVOKABLE QVector3D toVector3D() const;",
                "Q_INVOKABLE static {cls} fromVector3D(const QVector3D& v);",
            ],
            "qml_methods": [
                {
                    "signature": "QVector3D {vt}::toVector3D()",
                    "brief": "Return a single-precision \\l QVector3D with the same components.",
                },
                {
                    "static_factory": True,
                    "signature": "{vt} {se}::fromVector3D(QVector3D v)",
                    "brief": "Construct from a single-precision \\l QVector3D.",
                },
            ],
            "extra_includes": ["<QVector3D>"],
            "extra_cpp_includes": [],
            "cpp_impl_tmpl": (
                "QVector3D {ns}::{cls}::toVector3D() const\n"
                "{{\n"
                "    return QVector3D(static_cast<float>(m_x),\n"
                "                     static_cast<float>(m_y),\n"
                "                     static_cast<float>(m_z));\n"
                "}}\n"
                "\n"
                "{ns}::{cls} {ns}::{cls}::fromVector3D(const QVector3D& v)\n"
                "{{\n"
                "    {ns}::{cls} r;\n"
                "    r.m_x = v.x();\n"
                "    r.m_y = v.y();\n"
                "    r.m_z = v.z();\n"
                "    return r;\n"
                "}}\n"
            ),
        },
    ],
    "geometry_msgs/Point": [
        {
            "is_computed": True,
            "name": "qvector3dBridges",
            "property_spec": None,
            "getter_decl": None,
            "setter_decl": None,
            "extra_decls": [
                "Q_INVOKABLE QVector3D toVector3D() const;",
                "Q_INVOKABLE static {cls} fromVector3D(const QVector3D& v);",
            ],
            "qml_methods": [
                {
                    "signature": "QVector3D {vt}::toVector3D()",
                    "brief": "Return a single-precision \\l QVector3D with the same components.",
                },
                {
                    "static_factory": True,
                    "signature": "{vt} {se}::fromVector3D(QVector3D v)",
                    "brief": "Construct from a single-precision \\l QVector3D.",
                },
            ],
            "extra_includes": ["<QVector3D>"],
            "extra_cpp_includes": [],
            "cpp_impl_tmpl": (
                "QVector3D {ns}::{cls}::toVector3D() const\n"
                "{{\n"
                "    return QVector3D(static_cast<float>(m_x),\n"
                "                     static_cast<float>(m_y),\n"
                "                     static_cast<float>(m_z));\n"
                "}}\n"
                "\n"
                "{ns}::{cls} {ns}::{cls}::fromVector3D(const QVector3D& v)\n"
                "{{\n"
                "    {ns}::{cls} r;\n"
                "    r.m_x = v.x();\n"
                "    r.m_y = v.y();\n"
                "    r.m_z = v.z();\n"
                "    return r;\n"
                "}}\n"
            ),
        },
    ],
}


def build_message_context(package_name: str, message_spec, *, ros_include_override: str | None = None) -> Dict[str, Any]:
    """Prepare commonly used identifiers for message templates."""
    ns_list = message_spec.structure.namespaced_type.namespaces
    msg_name = message_spec.structure.namespaced_type.name
    header_file = to_snake_case(msg_name)
    ros_include_parts = ns_list + [header_file]
    ros_include = ros_include_override or "/".join(ros_include_parts) + ".hpp"

    return {
        "qt_namespace": get_qt_namespace(package_name),
        "qt_class_name": get_qt_class_name(package_name, msg_name),
        "qt_class_name_full": get_qt_class_name_full(package_name, msg_name),
        "qml_value_type_name": get_qml_value_type_name(package_name, msg_name),
        "qml_module_uri": get_qml_module_uri(package_name),
        "ros_msg_type": "::".join(ns_list + [msg_name]),
        "ros_include": ros_include,
        "header_file": header_file,
        "value_type_include": f"{header_file}.hpp",
    }


# Per-message overrides for single-field pub/sub type.  Keys are "package/MessageName".
# These bypass the normal field-type inspection and return a fully specified info dict.
_SINGLE_FIELD_TYPE_OVERRIDES: Dict[str, Dict[str, Any]] = {
    # uint8[16] uuid → QString (RFC 4122 without braces, e.g. "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx").
    # QUuid is not a QML value type so using it as a Q_PROPERTY would give QML an opaque var.
    "unique_identifier_msgs/UUID": {
        "qt_type":      "QString",
        "field_name":   "uuid",
        "param_decl":   "const QString& uuid",
        "ros_to_qt":    "QUuid::fromRfc4122(QByteArray("
                        "reinterpret_cast<const char*>(msg->uuid.data()), 16))"
                        ".toString(QUuid::WithoutBraces)",
        "qt_to_ros":    "const QByteArray _b = QUuid::fromString(uuid).toRfc4122();\n"
                        "    std::copy(_b.begin(), _b.end(), ros_msg.uuid.begin());",
        "extra_inc":    "<QtCore/QUuid>",
        "qml_doc_type": "string",
    },
}


def build_single_field_info(package_name: str, message_spec) -> Dict[str, Any] | None:
    """For single-field messages, return type/conversion info for direct use in pub/sub.

    Returns None for empty messages and messages with 2+ fields.
    """
    msg_name = message_spec.structure.namespaced_type.name
    key = f"{package_name}/{msg_name}"
    if key in _SINGLE_FIELD_TYPE_OVERRIDES:
        return _SINGLE_FIELD_TYPE_OVERRIDES[key]

    members = message_spec.structure.members
    if len(members) != 1 or members[0].name == 'structure_needs_at_least_one_member':
        return None

    member = members[0]
    field_name = member.name
    field_type = member.type

    # Array/sequence fields need non-trivial conversions — keep the wrapper for those.
    if isinstance(field_type, (Array, BoundedSequence, UnboundedSequence)):
        return None

    resolved_type = field_type
    if isinstance(resolved_type, AbstractNestedType):
        resolved_type = resolved_type.value_type

    qt_type = msg_type_to_qt_full(field_type)

    if isinstance(resolved_type, AbstractWString):
        ros_to_qt = f'QString::fromStdWString(msg->{field_name})'
        qt_to_ros = f'ros_msg.{field_name} = {field_name}.toStdWString();'
        extra_inc = '<QtCore/QString>'
        const_ref = True
    elif isinstance(resolved_type, AbstractString):
        ros_to_qt = f'QString::fromStdString(msg->{field_name})'
        qt_to_ros = f'ros_msg.{field_name} = {field_name}.toStdString();'
        extra_inc = '<QtCore/QString>'
        const_ref = True
    elif isinstance(resolved_type, NamespacedType):
        nested_pkg = resolved_type.namespaces[0] if resolved_type.namespaces else package_name
        nested_ros = '::'.join(resolved_type.namespaces + [resolved_type.name])
        nested_qt  = get_qt_class_name_full(nested_pkg, resolved_type.name)
        ros_to_qt  = f'{nested_qt}(msg->{field_name})'
        qt_to_ros  = f'ros_msg.{field_name} = static_cast<{nested_ros}>({field_name});'
        extra_inc  = to_snake_case(resolved_type.name) + '.hpp'
        const_ref  = True
    else:
        ros_to_qt = f'msg->{field_name}'
        qt_to_ros = f'ros_msg.{field_name} = {field_name};'
        extra_inc = None
        const_ref = False

    _QT_TO_QML: Dict[str, str] = {'QString': 'string', 'QStringList': 'list<string>'}
    if isinstance(resolved_type, NamespacedType):
        nested_pkg = resolved_type.namespaces[0] if resolved_type.namespaces else package_name
        qml_doc_type = get_qml_value_type_name(nested_pkg, resolved_type.name)
    else:
        qml_doc_type = _QT_TO_QML.get(qt_type, qt_type)

    param_decl = f'const {qt_type}& {field_name}' if const_ref else f'{qt_type} {field_name}'

    return {
        'qt_type':      qt_type,
        'field_name':   field_name,
        'param_decl':   param_decl,
        'ros_to_qt':    ros_to_qt,
        'qt_to_ros':    qt_to_ros,
        'extra_inc':    extra_inc,
        'qml_doc_type': qml_doc_type,
    }


# camelCase property/method names that must not be shadowed by generated per-field
# Q_PROPERTYs.  These come from the pub/sub base-class hierarchy and from the
# fixed properties/methods the pub/sub templates themselves always emit.
_PUBSUB_RESERVED_PROP_NAMES: frozenset = frozenset({
    'topic', 'node', 'qos',                   # QRos2Entity
    'subscriberCount',                         # QRos2PublisherBase
    'connected',                               # QRos2SubscriberBase
    'objectName', 'parent',                    # QObject
    'message',                                 # subscriber's own 'message' Q_PROPERTY
    'publish',                                 # publisher's publish() method
    'setupConnection', 'clearConnection',      # pure virtuals in both base classes
    'checkHealth', 'handleMessage',            # methods in generated pub/sub
})


def build_field_props_for_pubsub(package_name: str, message_spec) -> List[Dict[str, Any]] | None:
    """Per-field Q_PROPERTY descriptors for multi-field pub/sub templates.

    Returns None for empty messages and single-field messages (those are handled by
    build_single_field_info or suppressed). For messages with two or more fields,
    returns one descriptor per field with keys:
      qt_type, field_name, prop_name, setter_name, signal_name,
      param_decl, const_ref, getter_expr, qml_doc_type.

    Fields whose camelCase names collide with inherited base-class properties
    (topic, node, qos, …) are silently omitted.
    """
    members = message_spec.structure.members
    real_members = [m for m in members if m.name != 'structure_needs_at_least_one_member']
    if len(real_members) < 2:
        return None

    vt = build_value_type_descriptors(package_name, message_spec)
    real_infos = [fi for fi in vt['field_infos'] if not fi.get('is_computed')]

    result = []
    for fi in real_infos:
        prop_name = fi['qt_prop_name']
        if prop_name in _PUBSUB_RESERVED_PROP_NAMES:
            continue
        setter_name = 'set' + prop_name[0].upper() + prop_name[1:]
        signal_name = prop_name + 'Changed'
        const_ref = (
            fi['is_nested'] or fi['is_string'] or fi['is_wstring'] or fi['is_sequence']
        )
        qt_type = fi['qt_type']
        param_decl = f'const {qt_type}& {prop_name}' if const_ref else f'{qt_type} {prop_name}'
        result.append({
            'qt_type':      qt_type,
            'field_name':   fi['name'],
            'prop_name':    prop_name,
            'setter_name':  setter_name,
            'signal_name':  signal_name,
            'param_decl':   param_decl,
            'const_ref':    const_ref,
            'getter_expr':  f'm_message.{prop_name}()',
            'qml_doc_type': fi['qml_doc_type'],
        })

    return result if result else None


def build_value_type_descriptors(package_name: str, message_spec) -> Dict[str, Any]:
    """
    Compute field descriptors and nested includes needed by the value type template.
    Mirrors the logic previously embedded directly in the template.
    """
    nested_includes: List[NestedInclude] = []
    field_infos: List[Dict[str, Any]] = []
    post_init_lines: List[str] = []

    def add_nested_include(type_obj):
        if not isinstance(type_obj, NamespacedType):
            return
        nested_pkg = type_obj.namespaces[0] if type_obj.namespaces else package_name
        nested_name = type_obj.name
        is_cross = nested_pkg != package_name
        entry = (nested_pkg, nested_name, is_cross)
        if entry not in nested_includes:
            nested_includes.append(entry)

    for member in message_spec.structure.members:
        info: Dict[str, Any] = {
            "field": member,
            "name": member.name,
            "qt_type": msg_type_to_qt_full(member.type),
            "qt_prop_name": snake_to_camel(member.name),
        }

        field_type = member.type
        resolved_type = field_type
        if isinstance(resolved_type, AbstractNestedType):
            resolved_type = resolved_type.value_type

        info["is_array"] = isinstance(field_type, Array)
        info["is_dynamic_sequence"] = isinstance(field_type, (BoundedSequence, UnboundedSequence))
        info["is_sequence"] = info["is_array"] or info["is_dynamic_sequence"]
        info["sequence_value_type"] = field_type.value_type if info["is_sequence"] else None
        info["sequence_inner_qt"] = (
            msg_type_to_qt(info["sequence_value_type"]) if info["is_sequence"] else None
        )
        info["sequence_inner_is_nested"] = (
            isinstance(info["sequence_value_type"], NamespacedType) if info["is_sequence"] else False
        )
        info["is_qbytearray"] = info["qt_type"] == "QByteArray"
        info["is_qstring_list"] = info["qt_type"] == "QStringList"
        info["sequence_inner_is_wstring"] = (
            isinstance(info["sequence_value_type"], AbstractWString) if info["is_sequence"] else False
        )
        info["sequence_inner_is_string"] = (
            isinstance(info["sequence_value_type"], AbstractString) if info["is_sequence"] else False
        )
        info["sequence_ros_value_type"] = (
            msg_type_to_cpp(info["sequence_value_type"]) if info["is_sequence"] else None
        )

        info["resolved_type"] = resolved_type
        info["is_nested"] = isinstance(resolved_type, NamespacedType)
        info["nested_ros_type"] = (
            "::".join(resolved_type.namespaces + [resolved_type.name]) if info["is_nested"] else None
        )
        info["is_wstring"] = isinstance(resolved_type, AbstractWString)
        info["is_string"] = isinstance(resolved_type, AbstractString)

        # If the nested type is mapped to a Qt-native type (e.g. Point32 →
        # QVector3D), pre-compute the conversion expressions and route the
        # include through extra_includes instead of nested_includes.
        info["nested_mapping"] = get_namespaced_type_mapping(resolved_type) if info["is_nested"] else None
        info["sequence_inner_mapping"] = (
            get_namespaced_type_mapping(info["sequence_value_type"])
            if info["sequence_inner_is_nested"] else None
        )

        if info["is_nested"] and not info["nested_mapping"]:
            add_nested_include(resolved_type)
        if info["sequence_inner_is_nested"] and not info["sequence_inner_mapping"]:
            add_nested_include(info["sequence_value_type"])

        extra_includes = list(info.get("extra_includes") or [])
        if info["nested_mapping"]:
            inc = info["nested_mapping"]["include"]
            if inc not in extra_includes:
                extra_includes.append(inc)
        if info["sequence_inner_mapping"]:
            inc = info["sequence_inner_mapping"]["include"]
            if inc not in extra_includes:
                extra_includes.append(inc)
        if extra_includes:
            info["extra_includes"] = extra_includes

        if info["is_qstring_list"]:
            if info["sequence_inner_is_wstring"]:
                qt_conv = "QString::fromStdWString(value)"
                ros_conv = "value.toStdWString()"
            else:
                qt_conv = "QString::fromStdString(value)"
                ros_conv = "value.toStdString()"
            info["string_to_qt"] = qt_conv
            info["string_to_ros"] = ros_conv
            post_init_lines.append(f"        for (const auto& value : ros.{member.name}) {{")
            post_init_lines.append(f"            m_{member.name}.append({qt_conv});")
            post_init_lines.append("        }")
        elif info["is_sequence"] and (info["sequence_inner_is_string"] or info["sequence_inner_is_wstring"]):
            if info["sequence_inner_is_wstring"]:
                qt_conv = "QString::fromStdWString(value)"
                ros_conv = "value.toStdWString()"
            else:
                qt_conv = "QString::fromStdString(value)"
                ros_conv = "value.toStdString()"
            info["string_to_qt"] = qt_conv
            info["string_to_ros"] = ros_conv
            post_init_lines.append(f"        for (const auto& value : ros.{member.name}) {{")
            post_init_lines.append(f"            m_{member.name}.append({qt_conv});")
            post_init_lines.append("        }")

        if info["sequence_inner_is_nested"]:
            post_init_lines.append(
                f"        m_{member.name}.reserve(static_cast<int>(ros.{member.name}.size()));"
            )
            post_init_lines.append(f"        for (const auto& value : ros.{member.name}) {{")
            if info["sequence_inner_mapping"]:
                from_ros_expr = info["sequence_inner_mapping"]["from_ros"]("value")
                post_init_lines.append(f"            m_{member.name}.append({from_ros_expr});")
            else:
                post_init_lines.append(f"            m_{member.name}.append({info['sequence_inner_qt']}(value));")
            post_init_lines.append("        }")

        # QML-friendly type name used in \qmlproperty docs so qdoc can auto-link.
        _QT_TO_QML: Dict[str, str] = {"QString": "string", "QStringList": "list<string>"}
        if info["is_sequence"]:
            if info["is_qbytearray"]:
                info["qml_doc_type"] = "ArrayBuffer"
            elif info["is_qstring_list"] or info["sequence_inner_is_string"] or info["sequence_inner_is_wstring"]:
                info["qml_doc_type"] = "list<string>"
            elif info["sequence_inner_is_nested"]:
                if info["sequence_inner_mapping"]:
                    info["qml_doc_type"] = f"list<{info['sequence_inner_mapping']['qml_doc_type']}>"
                else:
                    inner = info["sequence_value_type"]
                    pkg = inner.namespaces[0] if inner.namespaces else package_name
                    info["qml_doc_type"] = f"list<{get_qml_value_type_name(pkg, inner.name)}>"
            else:
                inner_qt = info["sequence_inner_qt"] or ""
                info["qml_doc_type"] = f"list<{inner_qt}>"
        elif info["is_nested"]:
            if info["nested_mapping"]:
                info["qml_doc_type"] = info["nested_mapping"]["qml_doc_type"]
            else:
                t = resolved_type
                pkg = t.namespaces[0] if t.namespaces else package_name
                info["qml_doc_type"] = get_qml_value_type_name(pkg, t.name)
        else:
            info["qml_doc_type"] = _QT_TO_QML.get(info["qt_type"], info["qt_type"])

        field_infos.append(info)

    msg_name = message_spec.structure.namespaced_type.name
    pkg_msg_key = f"{package_name}/{msg_name}"
    qt_ns = get_qt_namespace(package_name)
    qt_cls = get_qt_class_name(package_name, msg_name)
    vt = get_qml_value_type_name(package_name, msg_name)
    for tmpl in _COMPUTED_PROPERTIES.get(pkg_msg_key, []):
        entry: Dict[str, Any] = dict(tmpl)
        if "cpp_impl_tmpl" in entry:
            entry["cpp_impl"] = entry.pop("cpp_impl_tmpl").format(ns=qt_ns, cls=qt_cls)
        if entry.get("extra_decls"):
            entry["extra_decls"] = [d.format(ns=qt_ns, cls=qt_cls) for d in entry["extra_decls"]]
        if entry.get("qml_methods"):
            entry["qml_methods"] = [
                {**m, "signature": m["signature"].format(vt=vt, se=qt_cls)}
                for m in entry["qml_methods"]
            ]
        field_infos.append(entry)

    return {
        "nested_includes": nested_includes,
        "field_infos": field_infos,
        "post_init_lines": post_init_lines,
    }


# Matches a generated "Q_INVOKABLE static <ret> <name>(<params>)" declaration.
_STATIC_FACTORY_RE = re.compile(
    r'Q_INVOKABLE\s+static\s+(?P<ret>[\w:]+)\s+(?P<name>\w+)\s*\((?P<params>[^)]*)\)'
)


def _split_cpp_params(param_str: str) -> List[Dict[str, str]]:
    """Split a C++ parameter list into {decl, name, base_type} descriptors."""
    params: List[Dict[str, str]] = []
    for raw in (p.strip() for p in param_str.split(',')):
        if not raw:
            continue
        name_match = re.search(r'(\w+)\s*$', raw)
        name = name_match.group(1) if name_match else ''
        type_str = raw[:raw.rfind(name)].strip() if name else raw
        base = re.sub(r'^const\s+', '', type_str).rstrip(' &').strip()
        params.append({"decl": raw, "name": name, "base_type": base})
    return params


def build_factory_singleton(package_name: str, message_spec) -> Dict[str, Any]:
    """Descriptors for a QML singleton (QRos2<Name>Utils) that re-exposes a value
    type's `Q_INVOKABLE static` factory methods.

    Static methods on a QML_VALUE_TYPE gadget are not callable from QML, so the
    factories (e.g. quaternion::fromEulerAngles) are unreachable without a
    companion QObject singleton — mirroring QtQuick3D's `Quaternion` helper.
    Returns has_factories=False when the type has no static factories.
    """
    msg_name = message_spec.structure.namespaced_type.name
    qt_ns = get_qt_namespace(package_name)
    qt_cls = get_qt_class_name(package_name, msg_name)
    qualified = f"{qt_ns}::{qt_cls}"

    vt = build_value_type_descriptors(package_name, message_spec)
    methods: List[Dict[str, Any]] = []
    qml_method_docs: List[Dict[str, Any]] = []
    for info in vt["field_infos"]:
        if not info.get("is_computed"):
            continue
        for decl in info.get("extra_decls") or []:
            m = _STATIC_FACTORY_RE.search(decl)
            if not m:
                continue
            params = _split_cpp_params(m.group("params"))
            methods.append({
                "ret": qualified,
                "name": m.group("name"),
                "param_decls": ", ".join(p["decl"] for p in params),
                "arg_names": ", ".join(p["name"] for p in params),
                # QtQuick3D-style convenience: a 3-scalar overload for the common
                # single-QVector3D factories (fromEulerAngles/fromRpy/fromVector3D).
                "vector3_overload": len(params) == 1 and params[0]["base_type"] == "QVector3D",
            })
        for qm in info.get("qml_methods") or []:
            if qm.get("static_factory"):
                qml_method_docs.append(qm)

    return {
        "has_factories": bool(methods),
        "methods": methods,
        "qml_method_docs": qml_method_docs,
        "qt_namespace": qt_ns,
        "gadget_class": qt_cls,
        "qualified_gadget": qualified,
        "singleton_class": f"QRos2{qt_cls}Utils",
        "qml_element": qt_cls,
        "qml_value_type_name": get_qml_value_type_name(package_name, msg_name),
        "qml_module_uri": get_qml_module_uri(package_name),
        "value_type_include": f"{to_snake_case(msg_name)}.hpp",
    }


def value_type_has_static_factories(package_name: str, message_spec) -> bool:
    """True if the value type has `Q_INVOKABLE static` factory methods that need a
    companion QML singleton (see build_factory_singleton)."""
    return build_factory_singleton(package_name, message_spec)["has_factories"]


def _strip_blank_edges(lines: List[str]) -> List[str]:
    out = list(lines)
    while out and not out[0].strip():
        out.pop(0)
    while out and not out[-1].strip():
        out.pop()
    return out


_HTML_ANCHOR_RE = re.compile(r'<a\s+href="([^"]+)"\s*>(.*?)</a>', re.IGNORECASE | re.DOTALL)
_HTML_TAG_RE = re.compile(r'<(/?)\s*(b|i|em|strong|tt|code|br)\s*/?>', re.IGNORECASE)
_BARE_URL_RE = re.compile(r'(?<![\w/{])(https?://[^\s<>"\']+?)(?=[.,;:)\]]?(?:\s|$))')
_HASH_BANNER_RE = re.compile(r'^\s*#{3,}\s*$')
_TRAILING_HASH_PAD_RE = re.compile(r'\s*#+\s*$')
_NUMBERED_LIST_RE = re.compile(r'^(\d+)[.)]\s+')
# Matches a list-item label: a bare word (identifier-like, possibly with .
# or / separators) followed by " - " or ": " and then some content.
_LIST_LABEL_RE = re.compile(r'^[\w./]+\s*[-:]\s+\S')
# Matches a matrix/formula row like "[fx 0 cx]" or "K = [fx 0 cx]".
_CODE_ROW_RE = re.compile(r'^[A-Za-z_]\w*\s*=\s*[\[|]')


def _sanitize_doc_line(line: str) -> str:
    """Defensively neutralize sequences that would break a qdoc /*! ... */ block,
    and convert common HTML / markdown embedded in ROS .msg comments to qdoc markup."""
    line = line.replace("*/", "* /")
    line = _HTML_ANCHOR_RE.sub(lambda m: r'\l {' + m.group(1) + '}{' + m.group(2).strip() + '}', line)
    line = _HTML_TAG_RE.sub('', line)
    # Bare URLs → qdoc \l links. Use the URL as both target and label so the
    # full address shows in the rendered docs.
    line = _BARE_URL_RE.sub(lambda m: r'\l {' + m.group(1) + '}{' + m.group(1) + '}', line)
    return line


def _strip_banner_and_padding(lines: List[str]) -> List[str]:
    """Drop hash-banner lines ('######...'), strip trailing '#' padding
    that some .msg authors use to box section title comments, and collapse
    "banner / title / banner" trios into a qdoc \\section1 heading."""
    out: List[str] = []
    i = 0
    while i < len(lines):
        ln = lines[i]
        if _HASH_BANNER_RE.match(ln):
            # Banner trio "###... / title / ###..." → \section1 title
            if i + 2 < len(lines) and _HASH_BANNER_RE.match(lines[i + 2]):
                title = _TRAILING_HASH_PAD_RE.sub('', lines[i + 1]).strip()
                if title:
                    if out and out[-1].strip():
                        out.append('')
                    out.append(r'\section1 ' + title)
                    out.append('')
                    i += 3
                    continue
            # Lone banner line: drop.
            i += 1
            continue
        stripped = _TRAILING_HASH_PAD_RE.sub('', ln).rstrip()
        out.append(stripped)
        i += 1
    return out


def _parse_msg_comments(msg_path: 'Path') -> Tuple[List[str], Dict[str, List[str]]]:
    """Re-parse a ROS .msg file to recover comment-to-field attribution.

    rosidl_adapter splits multi-paragraph leading comments at blank lines and
    misattributes the trailing paragraphs to the first field. We re-parse the
    raw .msg here to apply a saner rule:

    - Comments that immediately precede a field (no blank line between) belong
      to that field.
    - All other leading comments (everything above the first field, separated
      from it by a blank line, possibly multi-paragraph) belong to the struct.
    - Comments between fields, separated from the next field by a blank line,
      are orphaned (rare; we drop them).

    Returns (struct_comment_lines, {field_name: field_comment_lines}).
    Paragraph breaks in struct_comment_lines are preserved as empty strings.
    """
    from pathlib import Path
    raw = Path(msg_path).read_text(encoding='utf-8', errors='replace').splitlines()
    struct_lines: List[str] = []
    field_doc_map: Dict[str, List[str]] = {}
    pending: List[str] = []
    seen_field = False

    def _strip_comment(line: str) -> str:
        text = line.lstrip().lstrip('#')
        return text[1:] if text.startswith(' ') else text

    def _flush_struct():
        if pending:
            if struct_lines:
                struct_lines.append('')
            struct_lines.extend(pending)
        del pending[:]

    def _is_constant(stripped: str) -> bool:
        # ROS constants: "<type> <UPPER_NAME> = <value>". Distinguished from
        # fields with default values by the all-caps name.
        if '=' not in stripped:
            return False
        tokens = stripped.split()
        if len(tokens) < 2:
            return False
        name = tokens[1].split('=', 1)[0]
        return bool(name) and name[0].isalpha() and name == name.upper()

    for raw_line in raw:
        line = raw_line.rstrip()
        stripped = line.lstrip()
        if not stripped:
            if not seen_field:
                _flush_struct()
            else:
                del pending[:]
        elif stripped.startswith('#'):
            pending.append(_strip_comment(line))
        elif _is_constant(stripped):
            # Constants aren't exposed as Q_PROPERTYs; any pending comments
            # documented this constant and should not bleed into struct or
            # subsequent field docs.
            del pending[:]
            seen_field = True
        else:
            # Real field. Leading comments above the first field are struct
            # docs even without an intervening blank line (Point, Accel etc.) —
            # but only if the struct has no prose yet; otherwise those comments
            # are per-field intent (e.g. CameraInfo's "Time of image
            # acquisition" comment immediately above `header`).
            if not seen_field and not struct_lines:
                _flush_struct()
            tokens = stripped.split()
            field_name = ''
            if len(tokens) >= 2:
                field_name = tokens[1].split('=', 1)[0]
            if field_name:
                if pending:
                    field_doc_map.setdefault(field_name, []).extend(pending)
                del pending[:]
                seen_field = True
            else:
                del pending[:]

    while struct_lines and not struct_lines[-1].strip():
        struct_lines.pop()
    return struct_lines, field_doc_map


def _looks_like_list_item(stripped: str) -> bool:
    """Heuristic: does this indented line look like a list item (vs. ASCII art)?

    True for lines starting with a bullet glyph, a numbered prefix ("1.", "2)"),
    a "name - description" / "name: description" / "name [type]: description"
    pattern. False for ASCII-art rows (lines fenced by ``|...|`` or starting
    with ``[`` / ``=``-aligned formulas).
    """
    if not stripped:
        return False
    if stripped[0] in '-*+•':
        return True
    if _NUMBERED_LIST_RE.match(stripped):
        return True
    # Matrix row or formula — not a list item.
    if stripped[0] in '|[':
        return False
    if '://' in stripped[:60]:
        return False
    # "name - description" / "name: description" where name is a single token.
    # Tight pattern avoids false positives on prose containing " - " or ":".
    return bool(_LIST_LABEL_RE.match(stripped))


def _list_item_text(stripped: str) -> str:
    """Strip the leading bullet / numeric prefix so it doesn't show up after
    qdoc's own bullet."""
    if stripped[0] in '-*+•':
        return stripped[1:].lstrip()
    m = _NUMBERED_LIST_RE.match(stripped)
    if m:
        return stripped[m.end():].lstrip()
    return stripped


def _format_list_items(lines: List[str]) -> List[str]:
    """Convert runs of indented list-item-looking lines to qdoc \\list / \\li markup.

    ROS .msg comments use leading-whitespace indentation for lists of named
    items (e.g. the image topic list in sensor_msgs/CameraInfo) but also for
    ASCII tables and matrix diagrams (e.g. Inertia's inertia tensor). qdoc
    treats both the same — we only wrap if the indented lines actually look
    like list items (see _looks_like_list_item).
    """
    result: List[str] = []
    in_list = False
    in_code = False

    def _looks_like_code_row(stripped: str) -> bool:
        # Matrix rows or formula lines: starts with "[" or "|", or matches
        # a "name = [..." style intro line.
        if not stripped:
            return False
        if stripped[0] in '[|':
            return True
        if _CODE_ROW_RE.match(stripped):
            return True
        return False

    for line in lines:
        stripped = line.lstrip()
        indented = len(line) > len(stripped) and bool(stripped)
        is_list_item = indented and _looks_like_list_item(stripped)
        # Code rows don't require indentation — matrix authors often write
        # the middle row of a 3-row matrix flush-left ("K = [...]") between
        # two indented bracket rows.
        is_code_row = not is_list_item and stripped and _looks_like_code_row(stripped)

        if is_list_item:
            if in_code:
                result.append(r'\endcode')
                in_code = False
            if not in_list:
                result.append(r'\list')
                in_list = True
            result.append(r'\li ' + _list_item_text(stripped))
        elif is_code_row:
            if in_list:
                result.append(r'\endlist')
                in_list = False
            if not in_code:
                result.append(r'\code')
                in_code = True
            result.append(line)
        else:
            if in_list:
                result.append(r'\endlist')
                in_list = False
            if in_code:
                result.append(r'\endcode')
                in_code = False
            result.append(line)
    if in_list:
        result.append(r'\endlist')
    if in_code:
        result.append(r'\endcode')
    return result


_DEPRECATED_RE = re.compile(r'\bdeprecated\b', re.IGNORECASE)
_DEPRECATED_VERSION_RE = re.compile(r'\b(?:as\s+of|since)\s+([\w]+)', re.IGNORECASE)
_DEPRECATED_FAVOUR_RE = re.compile(r'\bin\s+favou?r\s+of\s+(.+?)\.?\s*$', re.IGNORECASE)


def extract_doc_info(message_spec, *, interface_path: str | None = None) -> Dict[str, Any]:
    """
    Pull human-authored documentation out of a parsed ROS interface.

    The ROS .msg comments are preserved by rosidl_adapter as
    @verbatim(language="comment", ...) annotations on the struct and on
    each member. rosidl_parser exposes them via Annotatable.get_comment_lines(),
    but the adapter sometimes misattributes leading multi-paragraph comments
    to the first field. If ``interface_path`` points at an .idl that has a
    sibling .msg, we re-parse that .msg directly to recover the original
    attribution.

    Deprecation notices (lines containing the word "deprecated") are stripped
    from the main text and returned separately as ``deprecated`` /
    ``deprecated_since`` so templates can emit a qdoc \\deprecated tag.
    """
    from pathlib import Path
    struct_lines_raw: List[str] = []
    rosidl_field_docs: Dict[str, List[str]] = {}
    members = []
    if hasattr(message_spec, "structure") and hasattr(message_spec.structure, "members"):
        members = message_spec.structure.members

    msg_path: 'Path | None' = None
    if interface_path:
        candidate = Path(interface_path).with_suffix('.msg')
        if candidate.exists():
            msg_path = candidate

    if msg_path is not None:
        struct_lines_raw, rosidl_field_docs = _parse_msg_comments(msg_path)
    else:
        try:
            struct_lines_raw = list(message_spec.structure.get_comment_lines() or [])
        except (AttributeError, ValueError):
            struct_lines_raw = []
        for member in members:
            try:
                rosidl_field_docs[member.name] = list(member.get_comment_lines() or [])
            except (AttributeError, ValueError):
                rosidl_field_docs[member.name] = []

    msg_lines = [
        _sanitize_doc_line(ln)
        for ln in _strip_blank_edges(_strip_banner_and_padding(struct_lines_raw))
    ]

    # Detect and strip deprecation lines before building brief/details
    deprecated = False
    deprecated_since = ''
    clean_lines: List[str] = []
    for line in msg_lines:
        if _DEPRECATED_RE.search(line):
            deprecated = True
            if not deprecated_since:
                m = _DEPRECATED_VERSION_RE.search(line)
                if m:
                    deprecated_since = m.group(1)
            # "deprecated in favour of X" → capture as version-less detail
            # (kept in clean_lines so it becomes part of brief/details)
            if _DEPRECATED_FAVOUR_RE.search(line):
                clean_lines.append(line)
        else:
            clean_lines.append(line)
    if deprecated:
        msg_lines = list(_strip_blank_edges(clean_lines))

    # Split at the first blank line: everything before is the brief paragraph,
    # everything after is the detailed description. This preserves multi-line
    # first paragraphs so \brief doesn't end mid-sentence.
    first_blank = next((i for i, l in enumerate(msg_lines) if not l.strip()), len(msg_lines))
    brief_lines = msg_lines[:first_blank]
    details = _format_list_items(list(_strip_blank_edges(msg_lines[first_blank + 1:] if first_blank < len(msg_lines) else [])))

    brief = brief_lines[0].strip() if brief_lines else ""
    brief_continuation = brief_lines[1:] if len(brief_lines) > 1 else []

    # Per-field overrides for built-in messages whose comments are thin or absent.
    msg_name = (
        message_spec.structure.namespaced_type.name
        if hasattr(message_spec, "structure") else ""
    )
    package_name_for_msg = (
        message_spec.structure.namespaced_type.namespaces[0]
        if hasattr(message_spec, "structure")
        and getattr(message_spec.structure.namespaced_type, "namespaces", None)
        else ""
    )
    field_overrides = _FIELD_DOC_OVERRIDES.get(
        f"{package_name_for_msg}/{msg_name}", {}
    )

    field_docs: Dict[str, List[str]] = {}
    for member in members:
        if member.name in field_overrides:
            raw = list(field_overrides[member.name])
        else:
            raw = rosidl_field_docs.get(member.name, [])
        lines = _format_list_items([
            _sanitize_doc_line(ln)
            for ln in _strip_blank_edges(_strip_banner_and_padding(raw))
        ])
        field_docs[member.name] = lines

    return {
        "brief": brief,
        "brief_continuation": brief_continuation,
        "details": details,
        "field_docs": field_docs,
        "deprecated": deprecated,
        "deprecated_since": deprecated_since,
    }


def build_include_guard(*parts: str, suffix: str = "HPP") -> str:
    """
    Create a deterministic include guard identifier based on the provided parts.
    """
    tokens: List[str] = ["QTROS2"]
    for part in parts:
        normalized = re.sub(r"[^0-9A-Za-z]+", "_", part).strip("_")
        if normalized:
            tokens.append(normalized.upper())
    if suffix:
        tokens.append(suffix.upper())
    return "_".join(tokens)
