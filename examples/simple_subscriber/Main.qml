// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtRos2.Core
import QtRos2.GeometryMsgs as Geom

Window {
    id: root
    width: 400
    height: 360
    visible: true
    title: `Subscriber to Pose ${poseSubscriber.topic}`

    property int messageCount: 0

    property Geom.point position: poseSubscriber.pose.position
    property Geom.quaternion orientation: poseSubscriber.pose.orientation

    Node {
        id: rosNode
        nodeName: "simple_subscriber_node"
        Geom.PoseStampedSubscriber {
            id: poseSubscriber
            node: rosNode
            topic: topicField.text

            onMessageReceived: function (msg) {
                ++root.messageCount
                //console.log(JSON.stringify(msg))
            }
        }
    }

    GridLayout {
        columns: 2
        columnSpacing: 10
        x: 12; y: 12
        width: parent.width - 24

        Label {
            text: rosNode.initialized ? qsTr("ROS 2 Node Ready ") + (poseSubscriber.connected ?
                qsTr("(Publisher available)") : qsTr("(Waiting for publisher)")) : qsTr("Waiting for ROS 2...")
            font.bold: true
            Layout.columnSpan: 2
        }

        Label {
            text: qsTr("Messages received")
        }
        Label {
            text: root.messageCount
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
            text: qsTr("Frame ID")
            font.bold: true
        }

        Label {
            text: root.messageCount === 0 ? "---" :
                poseSubscriber.message.header.frameId // same as poseSubscriber.header.frameId
        }

        Label {
            text: qsTr("Time stamp")
            font.bold: true
            Layout.alignment: Qt.AlignTop
        }

        Label {
            text: root.messageCount === 0 ? "---" :
                `sec=${poseSubscriber.header.stamp.sec}\nnanosec=${poseSubscriber.header.stamp.nanosec}`
        }

        Label {
            text: qsTr("Position")
            font.bold: true
            Layout.alignment: Qt.AlignTop
        }

        Label {
            text: root.messageCount === 0 ? "---" :
                `x=${root.position.x}\ny=${root.position.y}\nz=${root.position.z}`
        }

        Label {
            text: qsTr("Orientation")
            font.bold: true
            Layout.alignment: Qt.AlignTop
        }

        Label {
            text: root.messageCount === 0 ? "---" :
                `x=${root.orientation.x}\ny=${root.orientation.y}\nz=${root.orientation.z}\nw=${root.orientation.w}`
        }

        Label {
            text: qsTr("Orientation Deg")
            font.bold: true
            Layout.alignment: Qt.AlignTop
        }

        Label {
            text: root.messageCount === 0 ? "---" :
                `x=${root.orientation.rpyDegrees.x}°\ny=${root.orientation.rpyDegrees.y}°\nz=${root.orientation.rpyDegrees.z}°`
        }
    }
}
