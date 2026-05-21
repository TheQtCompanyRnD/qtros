// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property var waypoints: []
    property string executionStatus: "idle" // idle, executing, completed, error
    property int currentWaypointIndex: -1
    property real progress: 0
    property bool loopEnabled: false

    signal playSequence
    signal stopSequence

    color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Execution Controls
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 140
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
                    Layout.fillWidth: true
                    spacing: 12

                    Button {
                        id: playButton
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        enabled: root.waypoints.length >= 2
                                 && root.executionStatus !== "executing"

                        background: Rectangle {
                            color: parent.enabled ? (playButton.pressed ? "#2DA35C" : Theme.success) : Theme.muted
                            radius: Theme.radius
                        }

                        contentItem: RowLayout {
                            spacing: 8

                            Label {
                                text: "▶"
                                color: "white"
                                font.pixelSize: 20
                            }

                            Label {
                                text: "Play"
                                color: "white"
                                font.pixelSize: 16
                                font.bold: true
                                Layout.fillWidth: true
                            }
                        }

                        onClicked: root.playSequence()
                    }

                    Button {
                        id: stopButton
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        enabled: root.executionStatus === "executing"

                        background: Rectangle {
                            color: parent.enabled ? (stopButton.pressed ? "#C74545" : Theme.destructive) : Theme.muted
                            radius: Theme.radius
                        }

                        contentItem: RowLayout {
                            spacing: 8

                            Label {
                                text: "■"
                                color: "white"
                                font.pixelSize: 18
                            }

                            Label {
                                text: "Stop"
                                color: "white"
                                font.pixelSize: 16
                                font.bold: true
                                Layout.fillWidth: true
                            }
                        }

                        onClicked: root.stopSequence()
                    }
                }

                CheckBox {
                    id: loopCheckbox
                    text: "Loop Sequence"
                    checked: root.loopEnabled
                    onToggled: root.loopEnabled = checked

                    contentItem: Label {
                        text: loopCheckbox.text
                        color: Theme.foreground
                        font.pixelSize: 13
                        leftPadding: loopCheckbox.indicator.width + 8
                        verticalAlignment: Text.AlignVCenter
                    }

                    indicator: Rectangle {
                        implicitWidth: 20
                        implicitHeight: 20
                        x: loopCheckbox.leftPadding
                        y: parent.height / 2 - height / 2
                        radius: 4
                        border.width: 2
                        border.color: loopCheckbox.checked ? Theme.primary : Theme.border
                        color: loopCheckbox.checked ? Theme.primary : "transparent"

                        Label {
                            visible: loopCheckbox.checked
                            anchors.centerIn: parent
                            text: "✓"
                            color: Theme.primaryForeground
                            font.pixelSize: 14
                        }
                    }
                }
            }
        }

        // Status Area
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
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: "STATUS"
                        color: Theme.mutedForeground
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredWidth: 10
                        Layout.preferredHeight: 10
                        radius: 5
                        color: {
                            if (root.executionStatus === "executing")
                            return Theme.primary
                            if (root.executionStatus === "completed")
                            return Theme.success
                            if (root.executionStatus === "error")
                            return Theme.destructive
                            return Theme.mutedForeground
                        }
                    }

                    Label {
                        text: root.executionStatus.charAt(0).toUpperCase(
                                  ) + root.executionStatus.slice(1)
                        color: Theme.foreground
                        font.pixelSize: 14
                        font.bold: true
                    }
                }

                ProgressBar {
                    Layout.fillWidth: true
                    value: root.progress
                    from: 0
                    to: 100

                    background: Rectangle {
                        implicitHeight: 8
                        color: Theme.muted
                        radius: 4
                    }

                    contentItem: Item {
                        implicitHeight: 8

                        Rectangle {
                            width: parent.width * (root.progress / 100)
                            height: parent.height
                            radius: 4
                            color: Theme.primary

                            Behavior on width {
                                NumberAnimation {
                                    duration: 200
                                }
                            }
                        }
                    }
                }

                Label {
                    text: {
                        if (root.executionStatus === "executing") {
                            return "Executing waypoint " + (root.currentWaypointIndex + 1)
                            + " of " + root.waypoints.length
                        }
                        if (root.executionStatus === "completed") {
                            return "Sequence completed (" + root.waypoints.length + " waypoints)"
                        }
                        if (root.executionStatus === "error") {
                            return "Error: Trajectory aborted"
                        }
                        if (root.waypoints.length >= 2) {
                            return root.waypoints.length + " waypoints ready"
                        }
                        return "Need at least 2 waypoints to execute"
                    }
                    color: Theme.mutedForeground
                    font.pixelSize: 12
                }
            }
        }

        // Timeline Visualization
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
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

                Label {
                    text: "TIMELINE"
                    color: Theme.mutedForeground
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                    ScrollBar.horizontal.policy: ScrollBar.AsNeeded

                    Row {
                        spacing: 0

                        Repeater {
                            model: root.waypoints

                            Row {
                                id: timeLineDot
                                spacing: 0
                                required property int index
                                required property var modelData

                                Item {
                                    width: 40
                                    height: 40

                                    Rectangle {
                                        width: 32
                                        height: 32
                                        radius: 16

                                        anchors.centerIn: parent
                                        color: {
                                            if (timeLineDot.index === root.currentWaypointIndex
                                                && root.executionStatus === "executing") {
                                                return Theme.primary
                                            }
                                            if (timeLineDot.index < root.currentWaypointIndex
                                                && root.executionStatus === "executing") {
                                                return Theme.success
                                            }
                                            return Theme.mutedForeground
                                        }

                                        Label {
                                            anchors.centerIn: parent
                                            text: (timeLineDot.index + 1).toString()
                                            color: "white"
                                            font.pixelSize: 12
                                            font.bold: true
                                        }

                                        // Glow effect for active waypoint
                                        Rectangle {
                                            id: glowEffect
                                            visible: timeLineDot.index === root.currentWaypointIndex
                                                     && root.executionStatus === "executing"
                                            anchors.centerIn: parent
                                            width: parent.width + 8
                                            height: parent.height + 8
                                            radius: (parent.width + 8) / 2
                                            color: "transparent"
                                            border.width: 2
                                            border.color: Theme.primary
                                            opacity: 0.5

                                            SequentialAnimation on opacity {
                                                running: glowEffect.visible
                                                loops: Animation.Infinite
                                                NumberAnimation {
                                                    from: 0.5
                                                    to: 0
                                                    duration: 1000
                                                }
                                                NumberAnimation {
                                                    from: 0
                                                    to: 0.5
                                                    duration: 1000
                                                }
                                            }
                                        }
                                    }
                                }

                                // Connection line (not for last waypoint)
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: index < root.waypoints.length - 1
                                    width: 40
                                    height: 2

                                    color: {
                                        if (index < root.currentWaypointIndex
                                            && root.executionStatus === "executing") {
                                            return Theme.success
                                        }
                                        return Theme.muted
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Validation message
        Rectangle {
            visible: root.waypoints.length < 2
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 16

                Label {
                    text: "▶"
                    font.pixelSize: 48
                    color: Theme.mutedForeground
                    opacity: 0.3
                    Layout.alignment: Qt.AlignHCenter
                }

                Label {
                    text: "Not enough waypoints"
                    color: Theme.mutedForeground
                    font.pixelSize: 16
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                Label {
                    text: "Add at least 2 waypoints to execute a sequence"
                    color: Theme.mutedForeground
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        Item {
            visible: root.waypoints.length >= 2
            Layout.fillHeight: true
        }
    }
}
