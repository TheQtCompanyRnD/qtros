# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

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
    get_qt_class_name,
    get_qt_class_name_full,
    get_qt_namespace,
    msg_type_to_qt,
    msg_type_to_qt_full,
    msg_type_to_cpp,
    snake_to_camel,
    to_snake_case,
)

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
        "ros_msg_type": "::".join(ns_list + [msg_name]),
        "ros_include": ros_include,
        "header_file": header_file,
        "value_type_include": f"{header_file}.hpp",
    }


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

        if info["is_nested"]:
            add_nested_include(resolved_type)
        if info["sequence_inner_is_nested"]:
            add_nested_include(info["sequence_value_type"])

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
            post_init_lines.append(f"            m_{member.name}.append({info['sequence_inner_qt']}(value));")
            post_init_lines.append("        }")

        field_infos.append(info)

    msg_name = message_spec.structure.namespaced_type.name
    pkg_msg_key = f"{package_name}/{msg_name}"
    qt_ns = get_qt_namespace(package_name)
    qt_cls = get_qt_class_name(package_name, msg_name)
    for tmpl in _COMPUTED_PROPERTIES.get(pkg_msg_key, []):
        entry: Dict[str, Any] = dict(tmpl)
        if "cpp_impl_tmpl" in entry:
            entry["cpp_impl"] = entry.pop("cpp_impl_tmpl").format(ns=qt_ns, cls=qt_cls)
        field_infos.append(entry)

    return {
        "nested_includes": nested_includes,
        "field_infos": field_infos,
        "post_init_lines": post_init_lines,
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
