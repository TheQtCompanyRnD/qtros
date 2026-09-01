// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick.Dialogs
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: colorSettings
    required property color color
    height: row.height

    ColorDialog {
        id: colorDialog
        selectedColor: colorSettings.color
        options: ColorDialog.DontUseNativeDialog
        onAccepted: colorSettings.color = selectedColor
    }

    RowLayout {
        id: row
        width: parent.width
        spacing: Theme.spacingSmall

        Label {
            text: "Color"
            color: Theme.foreground
            font.pixelSize: 16
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }
        Rectangle {
            border.width: 1
            border.color: Theme.primary
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            radius: 4
            color: colorSettings.color

            Layout.alignment: Qt.AlignVCenter
        }

        StyledButton {
            text: "Change"
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: 16

            onClicked: colorDialog.open()
        }
    }
}
