// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick
import QtQuick3D
import QtTest
import QtRos2.GeometryMsgs as Ros

TestCase {
    id: tc
    name: "Quaternion"

    readonly property real sqrtHalf: Math.SQRT1_2 // cos(45°) = sin(45°) ≈ 0.7071

    // A default-constructed ROS quaternion must be the identity (w = 1), not all
    // zeros — verifies the IDL @default(value=1.0) is honored.
    property Ros.quaternion qDefault
    function test_default_is_identity() {
        compare(qDefault.x, 0)
        compare(qDefault.y, 0)
        compare(qDefault.z, 0)
        compare(qDefault.w, 1)
    }

    // Structured-value construction from a JS object (QML_STRUCTURED_VALUE).
    property Ros.quaternion qObj: ({ x: 0.1, y: 0.2, z: 0.3, w: 0.4 })
    function test_structured_value_from_jsobject() {
        fuzzyCompare(qObj.x, 0.1, 1e-9)
        fuzzyCompare(qObj.y, 0.2, 1e-9)
        fuzzyCompare(qObj.z, 0.3, 1e-9)
        fuzzyCompare(qObj.w, 0.4, 1e-9)
    }

    // Bridge factory singleton (Ros.Quaternion, not QtQuick3D's). A 90° rotation
    // is a unit quaternion with w = cos(45°) and |vector| = sin(45°). Axis-agnostic.
    function test_fromEulerAngles_vector() {
        let q = Ros.Quaternion.fromEulerAngles(Qt.vector3d(0, 90, 0))
        fuzzyCompare(q.w, sqrtHalf, 1e-4)
        fuzzyCompare(Math.hypot(q.x, q.y, q.z), sqrtHalf, 1e-4)
        fuzzyCompare(Math.hypot(q.x, q.y, q.z, q.w), 1.0, 1e-4) // unit norm
    }

    // The 3-scalar overload must agree with the QVector3D overload.
    function test_fromEulerAngles_scalar_overload() {
        let a = Ros.Quaternion.fromEulerAngles(Qt.vector3d(10, 20, 30))
        let b = Ros.Quaternion.fromEulerAngles(10, 20, 30)
        fuzzyCompare(a.x, b.x, 1e-9)
        fuzzyCompare(a.y, b.y, 1e-9)
        fuzzyCompare(a.z, b.z, 1e-9)
        fuzzyCompare(a.w, b.w, 1e-9)
    }

    // fromRpy (radians) must match fromEulerAngles (degrees).
    function test_fromRpy_matches_euler() {
        let e = Ros.Quaternion.fromEulerAngles(Qt.vector3d(0, 90, 0))
        let r = Ros.Quaternion.fromRpy(Qt.vector3d(0, Math.PI / 2, 0))
        fuzzyCompare(r.x, e.x, 1e-4)
        fuzzyCompare(r.y, e.y, 1e-4)
        fuzzyCompare(r.z, e.z, 1e-4)
        fuzzyCompare(r.w, e.w, 1e-4)
    }

    // Reading eulerAngles / rpy round-trips the input.
    function test_eulerAngles_roundtrip() {
        let q = Ros.Quaternion.fromEulerAngles(Qt.vector3d(0, 30, 0))
        fuzzyCompare(q.eulerAngles.x, 0, 1e-3)
        fuzzyCompare(q.eulerAngles.y, 30, 1e-3)
        fuzzyCompare(q.eulerAngles.z, 0, 1e-3)
    }
    function test_rpy_roundtrip() {
        let q = Ros.Quaternion.fromRpy(Qt.vector3d(0, 0.5, 0))
        fuzzyCompare(q.rpy.y, 0.5, 1e-4)
    }

    // rpy is a ROS vector3 (radians), rpyDegrees a ROS vector3 (degrees) — both
    // double precision and readable without QtQuick; eulerAngles (QVector3D,
    // degrees) must agree with rpyDegrees, and rpy must be rpyDegrees in radians.
    function test_rpy_rpyDegrees_eulerAngles_agree() {
        let q = Ros.Quaternion.fromEulerAngles(Qt.vector3d(0, 30, 0))
        fuzzyCompare(q.rpyDegrees.y, 30, 1e-3)
        fuzzyCompare(q.rpyDegrees.y, q.eulerAngles.y, 1e-3)
        fuzzyCompare(q.rpy.y, 30 * Math.PI / 180, 1e-4)
        fuzzyCompare(q.rpy.y, q.rpyDegrees.y * Math.PI / 180, 1e-9)
    }

    // toQuaternion() yields a QtQuick quaternion whose scalar == w.
    function test_toQuaternion_scalar_is_w() {
        let q = Ros.Quaternion.fromEulerAngles(Qt.vector3d(0, 90, 0))
        let qq = q.toQuaternion()
        fuzzyCompare(qq.scalar, q.w, 1e-4)
        fuzzyCompare(qq.x, q.x, 1e-4)
        fuzzyCompare(qq.y, q.y, 1e-4)
        fuzzyCompare(qq.z, q.z, 1e-4)
    }

    // fromQuaternion(Qt.quaternion(scalar, x, y, z)) maps scalar -> w.
    function test_fromQuaternion_maps_scalar_to_w() {
        let q = Ros.Quaternion.fromQuaternion(Qt.quaternion(sqrtHalf, 0, sqrtHalf, 0))
        fuzzyCompare(q.w, sqrtHalf, 1e-4)
        fuzzyCompare(q.y, sqrtHalf, 1e-4)
        fuzzyCompare(q.x, 0, 1e-4)
        fuzzyCompare(q.z, 0, 1e-4)
    }

    // Footgun guard: assigning a QtQuick3D Quaternion (whose real component is
    // "scalar") to a QObject's ROS-quaternion property — the digitwin's
    // PosePublisher.orientation scenario — must convert via the
    // Q_INVOKABLE Quaternion(QQuaternion) constructor, preserving w (not 0).
    Ros.PosePublisher {
        id: footgunPub
        orientation: Quaternion.fromEulerAngles(0, 90, 0) // QtQuick3D, not Ros.
    }
    function test_quick3d_assignment_preserves_w() {
        fuzzyCompare(footgunPub.orientation.w, sqrtHalf, 1e-4)
        fuzzyCompare(Math.hypot(footgunPub.orientation.x,
                                footgunPub.orientation.y,
                                footgunPub.orientation.z), sqrtHalf, 1e-4)
    }
}
