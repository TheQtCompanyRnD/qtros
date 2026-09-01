// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl
import QtQuick.Layouts

Rectangle {
    id: root

    radius: Theme.radius
    color: Theme.card
    border.color: Theme.border
    border.width: 1

    required property MainViewModel mainViewModel

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: Theme.radius
        anchors.bottomMargin: Theme.radius
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 48

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.border
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Repeater {
                    model: [{
                            "icon": "images/robot.svg",
                            "text": "Drive"
                        }, {
                            "icon": "images/gear.svg",
                            "text": "Layers"
                        }]

                    Item {
                        id: tabSelector
                        required property int index
                        required property var modelData

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 2
                            color: sideTabs.currentIndex === index ? Theme.primary : "transparent"
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            IconImage {
                                source: tabSelector.modelData.icon
                                Layout.preferredWidth: sideTabs.currentIndex
                                                       === tabSelector.index ? 30 : 25
                                Layout.preferredHeight: sideTabs.currentIndex
                                                        === tabSelector.index ? 30 : 25
                                Layout.alignment: Qt.AlignVCenter
                                color: sideTabs.currentIndex === tabSelector.index ? Theme.foreground : Theme.mutedForeground
                            }

                            Label {

                                Layout.alignment: Qt.AlignVCenter

                                text: tabSelector.modelData.text
                                color: sideTabs.currentIndex === tabSelector.index ? Theme.foreground : Theme.mutedForeground
                                font.pixelSize: sideTabs.currentIndex
                                                === tabSelector.index ? 16 : 14
                                font.bold: sideTabs.currentIndex === tabSelector.index
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: sideTabs.currentIndex = index
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
        }

        StackLayout {
            id: sideTabs
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: Theme.radius
            currentIndex: 0
            DrivePanel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                mainViewModel: root.mainViewModel
            }

            LayersPanel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                mainViewModel: root.mainViewModel
            }
        }
    }
}
