// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick.Controls.Basic

Button {
    id: root
    font.pixelSize: 24
    contentItem: Label {
        text: root.text
        font.pixelSize: root.font.pixelSize
        font.bold: true
        color: root.pressed ? Theme.primaryForeground : Theme.cardForeground
        horizontalAlignment: Label.AlignHCenter
        verticalAlignment: Label.AlignVCenter
    }

    background: Rectangle {
        radius: Theme.radius
        color: root.pressed ? Theme.primary : Theme.card
        border.color: root.pressed ? Theme.accent : Theme.border
        border.width: 1
    }
}
