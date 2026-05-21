// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtRos2.Core

Rectangle {
    id: root

    radius: Theme.radius
    color: Theme.card
    border.color: Theme.border
    border.width: 1

    required property MainViewModel mainViewModel

    function stateLabel(state) {
        switch (state) {
        case 1:
            return "requested"
        case 2:
            return "active"
        case 3:
            return "rejected"
        case 4:
            return "canceled"
        case 5:
            return "succeeded"
        case 6:
            return "aborted"
        default:
            return "idle"
        }
    }

    function stateColor(state) {
        switch (state) {
        case 2:
        case 5:
            return "#8fda72"
        case 1:
            return "#64b5f6"
        case 3:
        case 4:
        case 6:
            return "#ff8a65"
        default:
            return "#c0c0c0"
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.radius
        spacing: Theme.spacingLarge

        Rectangle {
            Layout.preferredWidth: 140
            Layout.preferredHeight: 48
            radius: Theme.radius
            color: Theme.secondary
            border.color: Theme.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingSmall
                spacing: 2
                Label {
                    text: "Subscribers"
                    color: Theme.mutedForeground
                    font.pixelSize: 11
                    font.bold: true
                }
                Label {
                    text: `${root.mainViewModel.connectedSubscribers}/${root.mainViewModel.totalSubscribers}`
                    color: Theme.foreground
                    font.pixelSize: 14
                    font.bold: true
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 140
            Layout.preferredHeight: 48
            radius: Theme.radius
            color: Theme.secondary
            border.color: Theme.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingSmall
                spacing: 2
                Label {
                    text: "Publishers"
                    color: Theme.mutedForeground
                    font.pixelSize: 11
                    font.bold: true
                }
                Label {
                    text: `${root.mainViewModel.connectedPublishers}/${root.mainViewModel.totalPublishers}`
                    color: Theme.foreground
                    font.pixelSize: 14
                    font.bold: true
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 140
            Layout.preferredHeight: 48
            radius: Theme.radius
            color: Theme.secondary
            border.color: Theme.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingSmall
                spacing: 2
                Label {
                    text: "Action Clients"
                    color: Theme.mutedForeground
                    font.pixelSize: 11
                    font.bold: true
                }
                Label {
                    text: `${root.mainViewModel.connectedActionClients}/${root.mainViewModel.totalActionClients}`
                    color: Theme.foreground
                    font.pixelSize: 14
                    font.bold: true
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Rectangle {
            id: navStatus
            Layout.preferredWidth: 500
            Layout.preferredHeight: 48
            radius: Theme.radius
            color: Theme.secondary
            border.color: Theme.border

            function formatSeconds(duration) {
                if (!duration)
                    return "--"
                const sec = Number(
                              duration.sec !== undefined ? duration.sec : duration.seconds)
                          || 0
                const nsec = Number(
                               duration.nanosec !== undefined ? duration.nanosec : duration.nsec)
                           || 0
                const total = sec + nsec / 1e9
                if (total <= 0)
                    return "--"
                if (total >= 60)
                    return (total / 60).toFixed(1) + " min"
                return total.toFixed(1) + " s"
            }

            function distanceText() {
                return root.mainViewModel.navigationStatus
                        === Ros2ActionClientBase.Accepted ? root.mainViewModel.navigationFeedback.distanceRemaining.toFixed(
                                                                2) + " m" : "---"
            }

            function navigationTimeText() {
                return root.mainViewModel.navigationStatus
                        === Ros2ActionClientBase.Accepted ? formatSeconds(
                                                                root.mainViewModel.navigationFeedback.navigationTime) : "--"
            }

            function etaText() {
                return root.mainViewModel.navigationStatus
                        === Ros2ActionClientBase.Accepted ? formatSeconds(
                                                                root.mainViewModel.navigationFeedback.estimatedTimeRemaining) : "--"
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingSmall
                spacing: 2

                Label {
                    text: "Navigate to pose"
                    color: Theme.mutedForeground
                    font.pixelSize: 11
                    font.bold: true
                }
                RowLayout {
                    spacing: Theme.spacingSmall
                    Layout.fillWidth: true
                    Label {
                        text: `Status:`
                        color: Theme.foreground
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Label {
                        text: root.stateLabel(
                                  root.mainViewModel.navigationStatus)
                        color: root.stateColor(
                                   root.mainViewModel.navigationStatus)
                        font.pixelSize: 14
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Label {
                        text: `Remaing: ${navStatus.distanceText()}`
                        color: Theme.foreground
                        font.pixelSize: 14
                        Layout.preferredWidth: 110
                        horizontalAlignment: Qt.AlignLeft
                        font.bold: true
                    }

                    Label {
                        text: `ETA: ${navStatus.etaText()}`
                        color: Theme.foreground
                        font.pixelSize: 14
                        Layout.preferredWidth: 110
                        horizontalAlignment: Qt.AlignLeft
                        font.bold: true
                    }

                    Label {
                        text: `Time: ${navStatus.navigationTimeText()}`
                        color: Theme.foreground
                        font.pixelSize: 14
                        Layout.preferredWidth: 110
                        horizontalAlignment: Qt.AlignLeft
                        font.bold: true
                    }
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 140
            Layout.preferredHeight: 48
            radius: Theme.radius
            color: Theme.secondary
            border.color: Theme.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingSmall
                spacing: 2
                Label {
                    text: "Undock"
                    color: Theme.mutedForeground
                    font.pixelSize: 11
                    font.bold: true
                }
                RowLayout {
                    spacing: Theme.spacingSmall
                    Layout.fillWidth: true
                    Label {
                        text: `Status:`
                        color: Theme.foreground
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Label {
                        text: root.stateLabel(root.mainViewModel.undockStatus)
                        color: root.stateColor(root.mainViewModel.undockStatus)
                        font.pixelSize: 14
                        font.bold: true
                        Layout.fillWidth: true
                    }
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 280
            Layout.preferredHeight: 48
            radius: Theme.radius
            color: Theme.secondary
            border.color: Theme.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingSmall
                spacing: 2
                Label {
                    text: "Dock"
                    color: Theme.mutedForeground
                    font.pixelSize: 11
                    font.bold: true
                }
                RowLayout {
                    spacing: Theme.spacingSmall
                    Layout.fillWidth: true
                    Label {
                        text: `Status:`
                        color: Theme.foreground
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Label {
                        text: root.stateLabel(root.mainViewModel.dockStatus)
                        color: root.stateColor(root.mainViewModel.dockStatus)
                        font.pixelSize: 14
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Label {
                        text: `Sees dock: ${root.mainViewModel.dockStatus
                              === Ros2ActionClientBase.Accepted ? root.mainViewModel.dockFeedback : "---"}`
                        color: Theme.foreground
                        font.pixelSize: 14
                        font.bold: true
                        Layout.preferredWidth: 110
                    }
                }
            }
        }
    }
}
