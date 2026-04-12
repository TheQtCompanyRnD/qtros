import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtRos2.GeometryMsgs

Window {
    id: root
    width: 480
    height: 600
    visible: true
    title: qsTr("QtROS2 Pose Publisher")

    property int publishCount: 0
    property string lastPayload: "Press the button to publish a PoseStamped message."

    Ros2Node {
        id: rosNode
        nodeName: "simple_publisher_node"

        PoseStampedPublisher {
            id: posePublisher
            topic: "/simple_publisher_pose"
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24

        Label {
            text: rosNode.initialized ? "ROS 2 Node Ready" : "Initializing ROS 2 Node..."
            font.bold: true
        }

        Label {
            text: `Subscribers count: ${posePublisher.subscriberCount}`
        }

        Label {
            text: "observe with: <b>ros2 topic echo /simple_publisher_pose<b>"
        }

        Button {
            text: rosNode.initialized ? "Publish Random Pose" : "Waiting for ROS..."
            enabled: rosNode.initialized

            onClicked: {
                const now = Date.now()
                const msg = {
                    "header": {
                        "frameId": "map",
                        "stamp": {
                            "sec": Math.floor(now / 1000),
                            "nanosec": Math.floor((now % 1000) * 1e6)
                        }
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

        TextArea {
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
