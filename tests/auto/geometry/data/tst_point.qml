// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick
import QtTest
import QtRos2.GeometryMsgs as Ros

TestCase {
    name: "Point"

    property Ros.point pDefault
    function test_default_is_zero() {
        compare(pDefault.x, 0)
        compare(pDefault.y, 0)
        compare(pDefault.z, 0)
    }

    property Ros.point pObj: ({ x: 1.5, y: -2.5, z: 3.5 })
    function test_structured_value_from_jsobject() {
        fuzzyCompare(pObj.x, 1.5, 1e-9)
        fuzzyCompare(pObj.y, -2.5, 1e-9)
        fuzzyCompare(pObj.z, 3.5, 1e-9)
    }

    function test_fromVector3D() {
        let p = Ros.Point.fromVector3D(Qt.vector3d(1, 2, 3))
        fuzzyCompare(p.x, 1, 1e-5)
        fuzzyCompare(p.y, 2, 1e-5)
        fuzzyCompare(p.z, 3, 1e-5)
    }

    function test_fromVector3D_scalar_overload() {
        let a = Ros.Point.fromVector3D(Qt.vector3d(4, 5, 6))
        let b = Ros.Point.fromVector3D(4, 5, 6)
        fuzzyCompare(a.x, b.x, 1e-9)
        fuzzyCompare(a.y, b.y, 1e-9)
        fuzzyCompare(a.z, b.z, 1e-9)
    }

    function test_toVector3D() {
        let p = Ros.Point.fromVector3D(7, 8, 9)
        let qv = p.toVector3D()
        fuzzyCompare(qv.x, 7, 1e-5)
        fuzzyCompare(qv.y, 8, 1e-5)
        fuzzyCompare(qv.z, 9, 1e-5)
    }

    property Ros.point pFromQt: Qt.vector3d(1, 2, 3)
    function test_qvector3d_assignment() {
        fuzzyCompare(pFromQt.x, 1, 1e-5)
        fuzzyCompare(pFromQt.y, 2, 1e-5)
        fuzzyCompare(pFromQt.z, 3, 1e-5)
    }
}
