import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl
import QtQuick.Layouts

ApplicationWindow {
    id: root
    width: 1400
    height: 900
    visible: true
    color: Theme.background
    title: "R6 Robot Teach Pendant"

    R6BotViewModel {
        id: mainViewModel
    }

    // Main Layout
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Status Bar
        StatusBar {
            Layout.fillWidth: true
            joints: mainViewModel.jointStates
        }

        // Main Content Area
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // 3D Viewer
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.background

                Rectangle {
                    anchors.right: parent.right
                    width: 1
                    height: parent.height
                    color: Theme.border
                }

                R6BotView3D {
                    id: robotView
                    anchors.fill: parent
                    mainViewModel: mainViewModel
                }

                // Quick capture button mirrors the axes toggle styling
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 16
                    width: capturePoseRow.width + 16
                    height: capturePoseRow.height + 12
                    color: "#cc202020"
                    radius: 6

                    Row {
                        id: capturePoseRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "Capture Pose"
                            color: "#e0e0e0"
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Button {
                            id: capturePoseButton
                            text: "Capture"
                            anchors.verticalCenter: parent.verticalCenter
                            hoverEnabled: true

                            background: Rectangle {
                                color: capturePoseButton.pressed ? Theme.accent : Theme.primary
                                radius: Theme.radius
                            }

                            contentItem: Label {
                                text: parent.text
                                color: Theme.primaryForeground
                                font.pixelSize: 12
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: {
                                if (waypointPanel) {
                                    waypointPanel.openCaptureDialog()
                                }
                            }
                        }
                    }
                }

                // Joint axes visibility toggle
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 16
                    width: axesToggleRow.width + 16
                    height: axesToggleRow.height + 12
                    color: "#cc202020"
                    radius: 6

                    Row {
                        id: axesToggleRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "Joint Axes"
                            color: "#e0e0e0"
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        CheckBox {
                            id: axesCheckbox
                            checked: true
                            anchors.verticalCenter: parent.verticalCenter

                            onCheckedChanged: {
                                robotView.showJointAxes = checked
                            }

                            indicator: Rectangle {
                                implicitWidth: 18
                                implicitHeight: 18
                                x: axesCheckbox.leftPadding
                                y: parent.height / 2 - height / 2
                                radius: 3
                                border.color: axesCheckbox.checked ? Theme.primary : Theme.border
                                border.width: 2
                                color: "transparent"

                                Rectangle {
                                    width: 10
                                    height: 10
                                    x: 4
                                    y: 4
                                    radius: 2
                                    color: Theme.primary
                                    visible: axesCheckbox.checked
                                }
                            }

                            background: Rectangle {
                                color: "transparent"
                            }
                        }
                    }
                }
            }

            // Control Panel with Tabs
            Rectangle {
                Layout.preferredWidth: Theme.sidePanelWidth
                Layout.fillHeight: true
                color: Theme.card

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Tab Bar
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
                            spacing: 0

                            Repeater {
                                model: [{
                                        "icon": "jog.svg",
                                        "text": "Jog"
                                    }, {
                                        "icon": "waypoint.svg",
                                        "text": "Waypoints"
                                    }, {
                                        "icon": "play.svg",
                                        "text": "Replay"
                                    }]

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    color: tabBar.currentIndex
                                           === index ? Theme.card : "transparent"

                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        height: 2
                                        color: tabBar.currentIndex
                                               === index ? Theme.primary : "transparent"
                                    }

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 8

                                        IconImage {
                                            source: modelData.icon
                                            Layout.preferredWidth: 30
                                            Layout.preferredHeight: 30
                                        }

                                        Label {
                                            text: modelData.text
                                            color: tabBar.currentIndex === index ? Theme.foreground : Theme.mutedForeground
                                            font.pixelSize: 14
                                            font.bold: tabBar.currentIndex === index
                                            Layout.alignment: Qt.AlignVCenter
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: tabBar.currentIndex = index
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                }
                            }
                        }
                    }

                    // Tab Content
                    StackLayout {
                        id: tabBar
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        currentIndex: 0

                        JogPanel {
                            mainViewModel: mainViewModel
                            connected: mainViewModel.connected

                            onJogJoint: (jointIndex, delta) => mainViewModel.jogJoint(
                                            jointIndex, delta)
                        }

                        WaypointPanel {
                            id: waypointPanel
                            positions: mainViewModel.currentPositions
                            waypoints: mainViewModel.waypoints

                            onCaptureWaypoint: (name, positions) => mainViewModel.captureWaypoint(
                                                   name, positions)
                            onDeleteWaypoint: index => mainViewModel.deleteWaypoint(
                                                  index)
                            onJumpToWaypoint: index => mainViewModel.jumpToWaypoint(
                                                  index)
                        }

                        ReplayPanel {
                            waypoints: mainViewModel.waypoints
                            executionStatus: mainViewModel.executionStatus
                            currentWaypointIndex: mainViewModel.currentWaypointIndex
                            progress: mainViewModel.executionProgress
                            loopEnabled: mainViewModel.loopEnabled

                            onPlaySequence: () => mainViewModel.playSequence()
                            onStopSequence: () => mainViewModel.stopSequence()
                            onLoopEnabledChanged: mainViewModel.loopEnabled = loopEnabled
                        }
                    }
                }
            }
        }
    }
}
