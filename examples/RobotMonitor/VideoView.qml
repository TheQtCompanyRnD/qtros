// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick.Controls

RosImageItem {
    id: videoDisplay
    width: 320
    height: 200

    Column {
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingSmall
        anchors.top: parent.top
        anchors.topMargin: Theme.spacingSmall
        spacing: 2

        Label {
            text: videoDisplay.image.width + "x" + videoDisplay.image.height
                  + " • " + videoDisplay.image.encoding
            color: Theme.foreground
            font.pixelSize: 10
        }
    }
}
