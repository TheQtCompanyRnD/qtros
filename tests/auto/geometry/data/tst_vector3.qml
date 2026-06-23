// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick
import QtTest
import QtRos2.GeometryMsgs as Ros

TestCase {
    name: "Vector3"

    property Ros.vector3 vDefault
    function test_default_is_zero() {
        compare(vDefault.x, 0)
        compare(vDefault.y, 0)
        compare(vDefault.z, 0)
    }

    property Ros.vector3 vObj: ({ x: 1.5, y: -2.5, z: 3.5 })
    function test_structured_value_from_jsobject() {
        fuzzyCompare(vObj.x, 1.5, 1e-9)
        fuzzyCompare(vObj.y, -2.5, 1e-9)
        fuzzyCompare(vObj.z, 3.5, 1e-9)
    }

    function test_fromVector3D() {
        let v = Ros.Vector3.fromVector3D(Qt.vector3d(1, 2, 3))
        fuzzyCompare(v.x, 1, 1e-5)
        fuzzyCompare(v.y, 2, 1e-5)
        fuzzyCompare(v.z, 3, 1e-5)
    }

    function test_fromVector3D_scalar_overload() {
        let a = Ros.Vector3.fromVector3D(Qt.vector3d(4, 5, 6))
        let b = Ros.Vector3.fromVector3D(4, 5, 6)
        fuzzyCompare(a.x, b.x, 1e-9)
        fuzzyCompare(a.y, b.y, 1e-9)
        fuzzyCompare(a.z, b.z, 1e-9)
    }

    function test_toVector3D() {
        let v = Ros.Vector3.fromVector3D(7, 8, 9)
        let qv = v.toVector3D()
        fuzzyCompare(qv.x, 7, 1e-5)
        fuzzyCompare(qv.y, 8, 1e-5)
        fuzzyCompare(qv.z, 9, 1e-5)
    }

    // Assigning a QtQuick vector3d (QVector3D) to a ROS vector3 property:
    // x/y/z share names, so this populates directly.
    property Ros.vector3 vFromQt: Qt.vector3d(1, 2, 3)
    function test_qvector3d_assignment() {
        fuzzyCompare(vFromQt.x, 1, 1e-5)
        fuzzyCompare(vFromQt.y, 2, 1e-5)
        fuzzyCompare(vFromQt.z, 3, 1e-5)
    }
}
