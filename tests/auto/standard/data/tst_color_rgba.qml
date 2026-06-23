// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick
import QtTest
import QtRos2.StdMsgs as Std

TestCase {
    name: "ColorRGBA"

    property Std.colorRGBA cDefault
    function test_default_is_zero() {
        compare(cDefault.r, 0)
        compare(cDefault.g, 0)
        compare(cDefault.b, 0)
        compare(cDefault.a, 0)
    }

    property Std.colorRGBA c: ({ r: 0.1, g: 0.2, b: 0.3, a: 1.0 })
    function test_structured_value_from_jsobject() {
        fuzzyCompare(c.r, 0.1, 1e-6)
        fuzzyCompare(c.g, 0.2, 1e-6)
        fuzzyCompare(c.b, 0.3, 1e-6)
        fuzzyCompare(c.a, 1.0, 1e-6)
    }
}
