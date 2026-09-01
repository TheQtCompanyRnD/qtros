// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick
import QtTest
import QtRos2.GeometryMsgs as Ros

TestCase {
    name: "Twist"

    property Ros.twist twistDefault
    function test_default_is_zero() {
        compare(twistDefault.linear.x, 0)
        compare(twistDefault.linear.y, 0)
        compare(twistDefault.linear.z, 0)
        compare(twistDefault.angular.x, 0)
        compare(twistDefault.angular.y, 0)
        compare(twistDefault.angular.z, 0)
    }

    // Mirrors the digitwin cmd_vel binding shape: linear/angular from Qt.vector3d.
    property Ros.twist twistObj: ({
        linear: Qt.vector3d(1, 2, 3),
        angular: Qt.vector3d(4, 5, 6)
    })
    function test_from_qvector3d() {
        fuzzyCompare(twistObj.linear.x, 1, 1e-5)
        fuzzyCompare(twistObj.linear.y, 2, 1e-5)
        fuzzyCompare(twistObj.linear.z, 3, 1e-5)
        fuzzyCompare(twistObj.angular.z, 6, 1e-5)
    }
}
