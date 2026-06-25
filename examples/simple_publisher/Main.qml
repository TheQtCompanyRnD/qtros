// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtRos2.GeometryMsgs

Window {
    id: root
    width: 480
    height: 600
    visible: true
    title: `Publisher to Pose ${posePublisher.topic}`

    property int publishCount: 0
    property string lastPayload: qsTr("Press the button to publish a PoseStamped message.")

    Node {
        id: rosNode
        nodeName: "simple_publisher_node"

        PoseStampedPublisher {
            id: posePublisher
            autoStamp: autoStampSwitch.checked
            topic: topicField.text
        }
    }

    GridLayout {
        columns: 2
        columnSpacing: 10
        anchors.fill: parent
        anchors.margins: 12

        Label {
            text: rosNode.initialized ? qsTr("ROS 2 Node Ready") : qsTr("Initializing ROS 2 Node...")
            font.bold: true
            Layout.columnSpan: 2
        }

        Label {
            Layout.row: 2
            text: qsTr("Subscribers count")
        }
        Label {
            text: posePublisher.subscriberCount
        }

        Label {
            text: qsTr("Topic")
            font.bold: true
        }
        TextField {
            id: topicField
            Layout.fillWidth: true
            text: "/simple_publisher_pose"
        }

        Label {
            text: qsTr("Frame")
            font.bold: true
        }
        TextField {
            id: frameField
            Layout.fillWidth: true
            text: "map"
        }

        Label {
            text: qsTr("Observe with")
            font.bold: true
        }
        TextField {
            Layout.fillWidth: true
            readOnly: true
            text: `ros2 topic echo ${posePublisher.topic}`
        }

        Button {
            text: rosNode.initialized ? qsTr("Publish Random Pose") : qsTr("Waiting for ROS...")
            enabled: rosNode.initialized

            onClicked: {
                // header.stamp intentionally left blank: the publisher fills it from the
                // ROS node clock (not Qt time) at publish time when autoStamp is true (the default).
                const msg = {
                    "header": {
                        "frameId": frameField.text
                    },
                    "pose": {
                        "position": {
                            "x": root.randomBetween(-5.0, 5.0),
                            "y": root.randomBetween(-5.0, 5.0),
                            "z": root.randomBetween(0.0, 2.0)
                        },
                        "orientation": root.randomQuaternion()
                    }
                }
                posePublisher.publish(msg)
                root.publishCount += 1
                root.lastPayload = `Publish #${root.publishCount}\n${JSON.stringify(
                            msg, null, 2)}`
            }
        }
        Switch {
            id: autoStampSwitch
            text: qsTr("Automatic time stamp")
            checked: true
        }

        TextArea {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            Layout.fillHeight: true
            readOnly: true
            wrapMode: TextEdit.Wrap
            text: root.lastPayload
        }
    }

    function randomBetween(min, max) {
        return min + Math.random() * (max - min)
    }

    function randomQuaternion() {
        var x = Math.random() * 2 - 1
        var y = Math.random() * 2 - 1
        var z = Math.random() * 2 - 1
        var w = Math.random() * 2 - 1
        var norm = Math.sqrt(x * x + y * y + z * z + w * w) || 1.0
        return {
            "x": x / norm,
            "y": y / norm,
            "z": z / norm,
            "w": w / norm
        }
    }
}
