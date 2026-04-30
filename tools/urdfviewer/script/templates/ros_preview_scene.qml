import QtQuick
import QtQuick.Controls
import QtQuick3D
import QtQuick3D.Helpers
import QtRos2.Core
import QtRos2.SensorMsgs as SensorMsgs

Item {
    id: root

    // Topic can be overridden at runtime, e.g. for namespaced robots.
    property string jointStateTopic: "{{ joint_states_topic }}"

    implicitWidth: 1920
    implicitHeight: 1080

    // Maps ROS joint names to QML property names on {{ base_name }}Control.
    // Generated from URDF at export time; update when joint names change.
    readonly property var _jointRosNameMap: ({
{% for entry in joint_map %}
        "{{ entry.ros_name }}": "{{ entry.qml_prop }}",
{% endfor %}
    })

    Ros2Node {
        id: ros2Node
        nodeName: "urdf_preview_node"

        SensorMsgs.JointStateSubscriber {
            id: jointStateSubscriber
            topic: root.jointStateTopic
            onMessageReceived: (msg) => {
                const names = msg.name
                const positions = msg.position
                for (let i = 0; i < names.length; ++i) {
                    const prop = root._jointRosNameMap[names[i]]
                    if (prop !== undefined)
                        robotControl[prop] = positions[i]
                }
            }
        }
    }

    {{ base_name }}Control {
        id: robotControl
    }

    View3D {
        id: view3D
        anchors.fill: parent

        camera: sceneCamera
        environment: sceneEnvironment

        SceneEnvironment {
            id: sceneEnvironment
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.High
        }

        Node {
            id: cameraNode
            eulerRotation: Qt.vector3d(-30, 30, 0)
            PerspectiveCamera {
                id: sceneCamera
                z: 1000
            }

            DirectionalLight {
                id: directionalLight
                eulerRotation: Qt.vector3d(-30, 30, 0)
            }
        }

        OrbitCameraController {
            origin: cameraNode
            camera: sceneCamera
        }

        AxisHelper {}

        {{ base_name }} {
            id: robotRoot
            control: robotControl
        }
    }

    // Shown until the ROS2 node has fully initialised
    Rectangle {
        visible: !ros2Node.initialized
        anchors.centerIn: parent
        color: "#cc000000"
        radius: 8
        width: statusLabel.implicitWidth + 32
        height: statusLabel.implicitHeight + 16

        Label {
            id: statusLabel
            anchors.centerIn: parent
            color: "white"
            text: qsTr("Waiting for ROS\u00b2\u2026")
        }
    }
}
