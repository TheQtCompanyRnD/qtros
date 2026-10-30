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

    // rpy / rpyDegrees are the ROS convention (Z-up, double precision), so the
    // quaternion on the wire has the rotation axis on the component named for it:
    // yaw -> z, pitch -> y, roll -> x.
    function test_fromRpyDegrees_ros_axes() {
        let yaw = Ros.Quaternion.fromRpyDegrees(Qt.vector3d(0, 0, 90))
        fuzzyCompare(yaw.z, sqrtHalf, 1e-4)
        fuzzyCompare(yaw.w, sqrtHalf, 1e-4)
        fuzzyCompare(yaw.x, 0, 1e-4)
        fuzzyCompare(yaw.y, 0, 1e-4)
        let pitch = Ros.Quaternion.fromRpyDegrees(Qt.vector3d(0, 90, 0))
        fuzzyCompare(pitch.y, sqrtHalf, 1e-4)
        fuzzyCompare(pitch.w, sqrtHalf, 1e-4)
        let roll = Ros.Quaternion.fromRpyDegrees(Qt.vector3d(90, 0, 0))
        fuzzyCompare(roll.x, sqrtHalf, 1e-4)
        fuzzyCompare(roll.w, sqrtHalf, 1e-4)
    }

    // fromRpy (radians) must match fromRpyDegrees.
    function test_fromRpy_matches_fromRpyDegrees() {
        let d = Ros.Quaternion.fromRpyDegrees(Qt.vector3d(10, 20, 30))
        let r = Ros.Quaternion.fromRpy(Qt.vector3d(10 * Math.PI / 180, 20 * Math.PI / 180, 30 * Math.PI / 180))
        fuzzyCompare(r.x, d.x, 1e-6)
        fuzzyCompare(r.y, d.y, 1e-6)
        fuzzyCompare(r.z, d.z, 1e-6)
        fuzzyCompare(r.w, d.w, 1e-6)
    }

    // Reading rpyDegrees / rpy round-trips the input (all three components).
    function test_rpyDegrees_roundtrip() {
        let q = Ros.Quaternion.fromRpyDegrees(Qt.vector3d(10, 20, 30))
        fuzzyCompare(q.rpyDegrees.x, 10, 1e-4)
        fuzzyCompare(q.rpyDegrees.y, 20, 1e-4)
        fuzzyCompare(q.rpyDegrees.z, 30, 1e-4)
        fuzzyCompare(q.rpy.x, 10 * Math.PI / 180, 1e-6)
        fuzzyCompare(q.rpy.y, 20 * Math.PI / 180, 1e-6)
        fuzzyCompare(q.rpy.z, 30 * Math.PI / 180, 1e-6)
    }

    // Yaw all the way round, including the sign, as SLAM reports it.
    function test_rpyDegrees_yaw_range() {
        for (const yaw of [-153.4, -90, -10, 10, 90, 153.4]) {
            let q = Ros.Quaternion.fromRpyDegrees(Qt.vector3d(0, 0, yaw))
            fuzzyCompare(q.rpyDegrees.z, yaw, 1e-4)
            fuzzyCompare(q.rpyDegrees.x, 0, 1e-4)
            fuzzyCompare(q.rpyDegrees.y, 0, 1e-4)
        }
    }

    // At pitch = +-90 roll and yaw are not independent; the orientation must still
    // round-trip, which is what matters.
    function test_rpy_gimbal_lock_roundtrips_orientation() {
        for (const pitch of [90, -90]) {
            let q = Ros.Quaternion.fromRpyDegrees(Qt.vector3d(0, pitch, 20))
            fuzzyCompare(q.rpyDegrees.y, pitch, 1e-4)
            let b = Ros.Quaternion.fromRpyDegrees(q.rpyDegrees)
            // q and -q are the same rotation
            const sign = (q.w * b.w + q.x * b.x + q.y * b.y + q.z * b.z) < 0 ? -1 : 1
            fuzzyCompare(sign * b.x, q.x, 1e-4)
            fuzzyCompare(sign * b.y, q.y, 1e-4)
            fuzzyCompare(sign * b.z, q.z, 1e-4)
            fuzzyCompare(sign * b.w, q.w, 1e-4)
        }
    }

    // eulerAngles is the Qt Quick 3D (Y-up) convenience: x = pitch about X,
    // y = yaw about the vertical Y axis, z = roll about Z, mapped from the ROS
    // quaternion with (x, y, z)_scene = (y, z, x)_ros. So a ROS yaw (about Z) is
    // the rotation about scene Y, a ROS pitch (about Y) about scene X, a ROS roll
    // (about X) about scene Z.
    function test_eulerAngles_yup_convention() {
        let yaw = Ros.Quaternion.fromRpyDegrees(Qt.vector3d(0, 0, 30))
        fuzzyCompare(yaw.eulerAngles.x, 0, 1e-3)
        fuzzyCompare(yaw.eulerAngles.y, 30, 1e-3)
        fuzzyCompare(yaw.eulerAngles.z, 0, 1e-3)
        let pitch = Ros.Quaternion.fromRpyDegrees(Qt.vector3d(0, 30, 0))
        fuzzyCompare(pitch.eulerAngles.x, 30, 1e-3)
        fuzzyCompare(pitch.eulerAngles.y, 0, 1e-3)
        fuzzyCompare(pitch.eulerAngles.z, 0, 1e-3)
        let roll = Ros.Quaternion.fromRpyDegrees(Qt.vector3d(30, 0, 0))
        fuzzyCompare(roll.eulerAngles.x, 0, 1e-3)
        fuzzyCompare(roll.eulerAngles.y, 0, 1e-3)
        fuzzyCompare(roll.eulerAngles.z, 30, 1e-3)
    }

    // fromEulerAngles is the inverse: Y-up yaw about Y -> ROS yaw about Z.
    function test_fromEulerAngles_yup_to_ros() {
        let q = Ros.Quaternion.fromEulerAngles(Qt.vector3d(0, 90, 0))
        fuzzyCompare(q.z, sqrtHalf, 1e-4)
        fuzzyCompare(q.w, sqrtHalf, 1e-4)
        fuzzyCompare(q.rpyDegrees.z, 90, 1e-3)
        let r = Ros.Quaternion.fromEulerAngles(Qt.vector3d(10, 20, 30))
        let back = r.eulerAngles
        fuzzyCompare(back.x, 10, 1e-3)
        fuzzyCompare(back.y, 20, 1e-3)
        fuzzyCompare(back.z, 30, 1e-3)
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
