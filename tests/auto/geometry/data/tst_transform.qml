// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick
import QtTest
import QtRos2.GeometryMsgs as Ros

TestCase {
    name: "Transform"

    // Default: zero translation, identity rotation (nested quaternion w = 1).
    property Ros.transform tfDefault
    function test_default() {
        compare(tfDefault.translation.x, 0)
        compare(tfDefault.translation.y, 0)
        compare(tfDefault.translation.z, 0)
        compare(tfDefault.rotation.w, 1)
    }

    property Ros.transform tfBuilt: ({
        translation: Qt.vector3d(1, 2, 3),
        rotation: Ros.Quaternion.fromEulerAngles(0, 90, 0)
    })
    function test_built_from_components() {
        fuzzyCompare(tfBuilt.translation.x, 1, 1e-5)
        fuzzyCompare(tfBuilt.translation.z, 3, 1e-5)
        fuzzyCompare(tfBuilt.rotation.w, Math.SQRT1_2, 1e-4)
    }
}
