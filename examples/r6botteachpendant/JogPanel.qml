// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    required property R6BotViewModel mainViewModel
    property bool connected: false
    property bool executing: false

    signal jogJoint(int jointIndex, real delta)

    color: "transparent"

    // Speed profile settings
    property int selectedSpeedProfile: 1 // 0=Fine, 1=Normal, 2=Fast
    property list<real> jogIncrements: [0.02, 0.1, 0.2] // Radians for each speed profile
    property real currentJogIncrement: jogIncrements[selectedSpeedProfile]

    Item {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                color: Theme.card

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Theme.border
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingMedium
                    spacing: 12

                    RowLayout {
                        spacing: 12

                        Label {
                            text: "⏱"
                            color: Theme.mutedForeground
                            font.pixelSize: 16
                        }

                        Label {
                            text: "SPEED PROFILE"
                            color: Theme.mutedForeground
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1
                        }
                    }

                    RowLayout {
                        spacing: 8
                        Layout.fillWidth: true

                        Repeater {
                            model: ["Fine", "Normal", "Fast"]
                            Button {
                                id: speedBtn
                                Layout.fillWidth: true
                                property bool isActive: index === root.selectedSpeedProfile
                                text: modelData
                                flat: true
                                font.pixelSize: 12

                                background: Rectangle {
                                    color: speedBtn.isActive ? Theme.primary : "transparent"
                                    radius: Theme.radius
                                    border.width: 1
                                    border.color: speedBtn.isActive ? Theme.primary : Theme.border
                                }

                                contentItem: Label {
                                    text: speedBtn.text
                                    color: speedBtn.isActive ? Theme.primaryForeground : Theme.foreground
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font: speedBtn.font
                                }

                                onClicked: {
                                    root.selectedSpeedProfile = index
                                    console.log("Speed profile changed to:",
                                                modelData, "Increment:",
                                                root.jogIncrements[index],
                                                "rad")
                                }
                            }
                        }
                    }
                }
            }

            // Joint Jog Grid
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth

                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ColumnLayout {
                    width: parent.parent.width - 2 * Theme.spacingMedium
                    spacing: Theme.spacingMedium
                    x: Theme.spacingMedium
                    y: Theme.spacingMedium

                    Repeater {
                        model: root.mainViewModel.jointStates

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 120
                            color: Theme.panel
                            radius: Theme.radius
                            border.width: 1
                            border.color: Theme.border

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                // Joint name and value
                                RowLayout {
                                    Layout.fillWidth: true

                                    Label {
                                        text: modelData.name
                                        color: Theme.foreground
                                        font.pixelSize: 14
                                        font.bold: true
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    Label {
                                        property real position: modelData.position
                                        text: position.toFixed(3) + " rad"
                                        color: Theme.foreground
                                        font.family: Theme.monoFontFamily
                                        font.pixelSize: 12
                                    }
                                }

                                // Joint limit bar
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 6
                                    radius: 3
                                    color: Theme.muted

                                    Rectangle {
                                        property real position: modelData.position
                                        property real percentage: (position + Math.PI)
                                                                  / (2 * Math.PI)

                                        width: parent.width * percentage
                                        height: parent.height
                                        radius: parent.radius
                                        color: Theme.primary
                                    }
                                }

                                // Jog buttons
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Button {
                                        id: minusBtn
                                        Layout.preferredWidth: 60
                                        Layout.preferredHeight: 60
                                        enabled: root.connected
                                                && !root.executing

                                        background: Rectangle {
                                            color: minusBtn.pressed ? "#8B4FD8" : "#9B5FE8"
                                            radius: Theme.radius
                                            opacity: minusBtn.enabled ? 1.0 : 0.3
                                        }

                                        contentItem: Label {
                                            text: "−"
                                            color: "white"
                                            font.pixelSize: 24
                                            font.bold: true
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        onPressed: root.jogJoint(
                                                       index,
                                                       -root.currentJogIncrement)
                                    }

                                    Item {
                                        Layout.fillWidth: true

                                        Label {
                                            anchors.centerIn: parent
                                            property real position: modelData.position
                                            property real percentage: ((position + Math.PI) / 6.28
                                                                       - 0.5) * 200
                                            text: percentage.toFixed(0) + "%"
                                            color: Theme.mutedForeground
                                            font.pixelSize: 12
                                        }
                                    }

                                    Button {
                                        id: plusBtn
                                        Layout.preferredWidth: 60
                                        Layout.preferredHeight: 60
                                        enabled: root.connected && !root.executing

                                        background: Rectangle {
                                            color: plusBtn.pressed ? Theme.primary : "#3BC9DB"
                                            radius: Theme.radius
                                            opacity: plusBtn.enabled ? 1.0 : 0.3
                                        }

                                        contentItem: Label {
                                            text: "+"
                                            color: Theme.primaryForeground
                                            font.pixelSize: 24
                                            font.bold: true
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        onPressed: root.jogJoint(
                                                       index,
                                                       root.currentJogIncrement)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
