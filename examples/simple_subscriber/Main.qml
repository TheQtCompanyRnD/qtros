import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtROS2.GeometryMsgs

Window {
    id: root
    width: 480
    height: 360
    visible: true
    title: qsTr("QtROS2 Pose Subscriber")

    property int messageCount: 0

    property qtros2geometrymsgs_point position: poseSubscriber.message.pose.position
    property qtros2geometrymsgs_quaternion orientation: poseSubscriber.message.pose.orientation

    ROS2Node {
        id: rosNode
        nodeName: "simple_subscriber_node"
        PoseStampedSubscriber {
            id: poseSubscriber
            node: rosNode
            topic: "/simple_publisher_pose"

            onMessageReceived: function (msg) {
                root.messageCount += 1
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24

        Label {
            text: rosNode.initialized ? "ROS 2 Node Ready" + (poseSubscriber.connected ? "(Publisher available)" : "(Waiting for publisher)") : "Waiting for ROS 2..."
            font.bold: true
        }

        Label {
            text: `Messages Received: ${root.messageCount}`
        }

        Grid {
            columns: 2
            columnSpacing: 10
            Label {
                text: "Frame ID"
                font.bold: true
            }

            Label {
                text: root.messageCount === 0 ? "---" : poseSubscriber.message.header.frameId
            }

            Label {
                text: "Time stamp"
                font.bold: true
            }

            Label {
                text: root.messageCount === 0 ? "---" : `sec=${poseSubscriber.message.header.stamp.sec}\nnanosec=${poseSubscriber.message.header.stamp.nanosec}`
            }

            Label {
                text: "Position"
                font.bold: true
            }

            Label {
                text: root.messageCount === 0 ? "---" : `x=${root.position.x}\ny=${root.position.y}\nz=${root.position.z}`
            }

            Label {
                text: "Orientation"
                font.bold: true
            }

            Label {
                text: root.messageCount === 0 ? "---" : `w=${root.orientation.w}\nx=${root.orientation.x}\ny=${root.orientation.y}\nz=${root.orientation.z}`
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
