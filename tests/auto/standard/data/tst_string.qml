// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick
import QtTest
import QtRos2.StdMsgs as Std

TestCase {
    name: "String"

    // std_msgs/String maps data <-> QString; QML value type is "rosString".
    property Std.rosString sDefault
    function test_default_is_empty() {
        compare(sDefault.data, "")
    }

    property Std.rosString s: ({ data: "héllo, ROS" })
    function test_structured_value_from_jsobject() {
        compare(s.data, "héllo, ROS")
    }
}
