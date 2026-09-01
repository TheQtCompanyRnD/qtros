// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl
import QtQuick.Layouts
import QtQuick.Window

Rectangle {
    id: root

    required property list<real> positions
    property var waypoints: []
    property Item overlayParent: root.Window.window ? root.Window.window.contentItem : null

    signal captureWaypoint(string name, list<real> positions)
    signal deleteWaypoint(int index)
    signal jumpToWaypoint(int index)

    function openCaptureDialog() {
        if (waypointNameField) {
            waypointNameField.text = "WP" + (root.waypoints.length + 1)
        }
        captureDialog.open()
    }

    color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Capture Bar
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

                Label {
                    text: "Uses current joint positions"
                    color: Theme.mutedForeground
                    font.pixelSize: 12
                }

                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48

                    background: Rectangle {
                        color: parent.pressed ? Theme.accent : Theme.primary
                        radius: Theme.radius
                    }

                    contentItem: RowLayout {
                        spacing: 8

                        Label {
                            text: "●"
                            color: Theme.primaryForeground
                            font.pixelSize: 20
                        }

                        Label {
                            text: "Capture Current Pose as Waypoint"
                            color: Theme.primaryForeground
                            font.pixelSize: 14
                            font.bold: true
                            Layout.fillWidth: true
                        }
                    }

                    onClicked: root.openCaptureDialog()
                }
            }
        }

        // Waypoint List Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: Theme.card

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.border
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingMedium
                anchors.rightMargin: Theme.spacingMedium

                Label {
                    text: root.waypoints.length + " waypoint"
                          + (root.waypoints.length !== 1 ? "s" : "")
                    color: Theme.foreground
                    font.pixelSize: 14
                    font.bold: true
                }

                Item {
                    Layout.fillWidth: true
                }

                Label {
                    visible: root.waypoints.length === 0
                    text: "No waypoints captured yet"
                    color: Theme.mutedForeground
                    font.pixelSize: 12
                    font.italic: true
                }
            }
        }

        // Waypoint List
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ListView {
                id: waypointList
                model: root.waypoints
                spacing: Theme.spacingSmall
                anchors.margins: Theme.spacingMedium

                delegate: Rectangle {
                    width: waypointList.width - Theme.spacingMedium * 2
                    height: 100
                    x: Theme.spacingMedium
                    color: Theme.panel
                    radius: Theme.radius
                    border.width: 1
                    border.color: Theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        // Drag handle
                        Rectangle {
                            Layout.preferredWidth: 24
                            Layout.fillHeight: true
                            color: "transparent"

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2
                                Repeater {
                                    model: 3
                                    Rectangle {
                                        width: 16
                                        height: 2
                                        radius: 1
                                        color: Theme.mutedForeground
                                    }
                                }
                            }
                        }

                        // Waypoint info
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 4

                            Label {
                                text: modelData.name
                                color: Theme.foreground
                                font.pixelSize: 14
                                font.bold: true
                            }

                            Label {
                                property string posStr: {
                                    if (modelData.positions
                                            && modelData.positions.length > 0) {
                                        return "J: [" + modelData.positions.map(
                                                    p => p.toFixed(2)).join(
                                                    ", ") + "]"
                                    }
                                    return "No position data"
                                }
                                text: posStr
                                color: Theme.mutedForeground
                                font.family: Theme.monoFontFamily
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 20
                                radius: 10
                                color: Theme.success + "33"
                                border.width: 1
                                border.color: Theme.success

                                Label {
                                    anchors.centerIn: parent
                                    text: "✓ OK"
                                    color: Theme.success
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                        }

                        // Action buttons
                        ColumnLayout {
                            spacing: 4

                            Button {
                                Layout.preferredWidth: 80
                                Layout.preferredHeight: 36

                                background: Rectangle {
                                    color: parent.pressed ? Theme.accent : Theme.primary
                                    radius: Theme.radius
                                }

                                contentItem: Label {
                                    text: "Jump"
                                    color: Theme.primaryForeground
                                    font.pixelSize: 12
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: root.jumpToWaypoint(index)
                            }

                            Button {
                                Layout.preferredWidth: 80
                                Layout.preferredHeight: 36

                                background: Rectangle {
                                    color: "transparent"
                                    radius: Theme.radius
                                    border.width: 1
                                    border.color: Theme.destructive
                                }

                                contentItem: Label {
                                    text: "🗑 Delete"
                                    color: Theme.destructive
                                    font.pixelSize: 11
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: deleteConfirmDialog.show(index)
                            }
                        }
                    }
                }
            }
        }

        // Info message
        Rectangle {
            visible: root.waypoints.length === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 16
                IconImage {
                    source: "waypoint.svg"
                    color: Theme.mutedForeground
                    opacity: 0.3
                    Layout.alignment: Qt.AlignHCenter
                    fillMode: IconImage.Stretch
                    sourceSize: Qt.size(120, 120)
                }

                Label {
                    text: "No waypoints yet"
                    color: Theme.mutedForeground
                    font.pixelSize: 16
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                Label {
                    text: "Capture your first waypoint using the button above"
                    color: Theme.mutedForeground
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // Note
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: Theme.muted

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: Theme.border
            }

            Label {
                anchors.centerIn: parent
                text: "⚠ Waypoints are not saved across sessions"
                color: Theme.mutedForeground
                font.pixelSize: 11
                font.italic: true
            }
        }
    }

    // Capture Dialog
    Dialog {
        id: captureDialog
        parent: overlayParent ? overlayParent : root
        anchors.centerIn: parent
        width: 500
        modal: true
        title: "New Waypoint"

        background: Rectangle {
            color: Theme.card
            radius: Theme.radius
            border.width: 1
            border.color: Theme.border
        }

        header: Rectangle {
            width: parent.width
            height: 60
            color: Theme.card
            radius: Theme.radius

            Label {
                anchors.centerIn: parent
                text: "New Waypoint"
                color: Theme.foreground
                font.pixelSize: 18
                font.bold: true
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.border
            }
        }

        ColumnLayout {
            width: parent.width
            spacing: Theme.spacingMedium

            Label {
                text: "Waypoint Name"
                color: Theme.foreground
                font.pixelSize: 14
            }

            TextField {
                id: waypointNameField
                Layout.fillWidth: true
                text: "WP" + (root.waypoints.length + 1)
                color: Theme.foreground
                font.pixelSize: 14
                selectByMouse: true

                background: Rectangle {
                    color: Theme.input
                    radius: Theme.radius
                    border.width: parent.activeFocus ? 2 : 1
                    border.color: parent.activeFocus ? Theme.primary : Theme.border
                }
            }

            Label {
                text: "Current Joint Positions"
                color: Theme.mutedForeground
                font.pixelSize: 12
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: Theme.panel
                radius: Theme.radius

                Label {
                    anchors.fill: parent
                    anchors.margins: 12
                    text: root.positions.length > 0 ? root.positions.map(
                                                          p => p.toFixed(
                                                              3)).join(
                                                          ", ") : "No position data available"
                    color: Theme.foreground
                    font.family: Theme.monoFontFamily
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
            }
        }

        footer: RowLayout {
            spacing: 8

            Button {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                text: "Cancel"

                background: Rectangle {
                    color: "transparent"
                    radius: Theme.radius
                    border.width: 1
                    border.color: Theme.border
                }

                contentItem: Label {
                    text: parent.text
                    color: Theme.foreground
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: captureDialog.close()
            }

            Button {
                Layout.fillWidth: true
                Layout.rightMargin: 10
                text: "Save"

                background: Rectangle {
                    color: Theme.primary
                    radius: Theme.radius
                }

                contentItem: Label {
                    text: parent.text
                    color: Theme.primaryForeground
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {

                    root.captureWaypoint(waypointNameField.text, root.positions)

                    captureDialog.close()
                }
            }
        }
    }

    // Delete Confirmation Dialog
    QtObject {
        id: deleteConfirmDialog
        property int targetIndex: -1

        function show(index) {
            targetIndex = index
            confirmDialog.open()
        }
    }

    Dialog {
        id: confirmDialog
        parent: overlayParent ? overlayParent : root

        anchors.centerIn: parent
        width: 350
        modal: true

        background: Rectangle {
            color: Theme.card
            radius: Theme.radius
            border.width: 1
            border.color: Theme.border
        }

        ColumnLayout {
            width: parent.width
            spacing: Theme.spacingMedium

            Label {
                text: "Delete Waypoint?"
                color: Theme.foreground
                font.pixelSize: 16
                font.bold: true
            }

            Label {
                text: deleteConfirmDialog.targetIndex >= 0
                      && deleteConfirmDialog.targetIndex
                      < root.waypoints.length ? "Are you sure you want to delete \"" + root.waypoints[deleteConfirmDialog.targetIndex].name + "\"?" : "Are you sure?"
                color: Theme.mutedForeground
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        footer: RowLayout {
            spacing: 8

            Button {
                Layout.leftMargin: 10
                Layout.fillWidth: true
                text: "Cancel"

                background: Rectangle {
                    color: "transparent"
                    radius: Theme.radius
                    border.width: 1
                    border.color: Theme.border
                }

                contentItem: Label {
                    text: parent.text
                    color: Theme.foreground
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: confirmDialog.close()
            }

            Button {
                Layout.rightMargin: 10
                Layout.fillWidth: true
                text: "Delete"

                background: Rectangle {
                    color: Theme.destructive
                    radius: Theme.radius
                }

                contentItem: Label {
                    text: parent.text
                    color: Theme.destructiveForeground
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    root.deleteWaypoint(deleteConfirmDialog.targetIndex)
                    confirmDialog.close()
                }
            }
        }
    }
}
