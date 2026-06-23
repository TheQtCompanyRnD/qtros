// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick
import QtTest
import QtRos2.SensorMsgs as Sensor

// Imu nests geometry value types (Quaternion, Vector3) from another module;
// this checks cross-module nested structured values and the identity default.
TestCase {
    name: "Imu"

    property Sensor.imu imuDefault
    function test_default_orientation_is_identity() {
        compare(imuDefault.orientation.w, 1)
        compare(imuDefault.angularVelocity.x, 0)
        compare(imuDefault.linearAcceleration.z, 0)
    }

    property Sensor.imu imu: ({
        orientation: ({ x: 0, y: 0, z: 0, w: 1 }),
        angularVelocity: ({ x: 1, y: 2, z: 3 }),
        linearAcceleration: ({ x: 4, y: 5, z: 6 })
    })
    function test_nested_structured_value() {
        compare(imu.orientation.w, 1)
        fuzzyCompare(imu.angularVelocity.x, 1, 1e-9)
        fuzzyCompare(imu.angularVelocity.z, 3, 1e-9)
        fuzzyCompare(imu.linearAcceleration.z, 6, 1e-9)
    }
}
