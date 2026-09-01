// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick
import QtTest
import QtRos2.GeometryMsgs as Ros

TestCase {
    name: "Pose"

    // Default pose: zero position, identity orientation (nested quaternion w = 1).
    property Ros.pose poseDefault
    function test_default() {
        compare(poseDefault.position.x, 0)
        compare(poseDefault.position.y, 0)
        compare(poseDefault.position.z, 0)
        compare(poseDefault.orientation.x, 0)
        compare(poseDefault.orientation.w, 1)
    }

    // Nested structured-value construction from JS objects.
    property Ros.pose poseObj: ({
        position: ({ x: 1, y: 2, z: 3 }),
        orientation: ({ x: 0, y: 0, z: 0, w: 1 })
    })
    function test_nested_jsobject() {
        fuzzyCompare(poseObj.position.x, 1, 1e-9)
        fuzzyCompare(poseObj.position.y, 2, 1e-9)
        fuzzyCompare(poseObj.position.z, 3, 1e-9)
        fuzzyCompare(poseObj.orientation.w, 1, 1e-9)
    }

    // Build a pose from a factory-constructed orientation.
    property Ros.pose poseBuilt: ({
        position: ({ x: 5, y: 6, z: 7 }),
        orientation: Ros.Quaternion.fromEulerAngles(0, 90, 0)
    })
    function test_built_from_components() {
        fuzzyCompare(poseBuilt.position.x, 5, 1e-9)
        fuzzyCompare(poseBuilt.orientation.w, Math.SQRT1_2, 1e-4)
    }
}
