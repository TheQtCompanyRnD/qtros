import QtQuick
import QtQuick.Controls
import QtQuick3D
import QtQuick3D.Helpers
{% if physics %}
import QtQuick3D.Physics
{% endif %}

Item {
    id: root
    implicitWidth: 1920
    implicitHeight: 1080

{% if ros %}
    {{ base_name }}Control {
        id: robotControl
    }

    // Subscribes to /joint_states and drives robotControl from ROS 2.
    RosBridge {
        id: rosBridge
        control: robotControl
    }

{% endif %}
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
{% if ros %}
            control: robotControl
{% else %}
            control: {{ base_name }}Control {}
{% endif %}
        }
    }
{% if physics %}

    PhysicsWorld {
        scene: view3D.scene
        gravity: Qt.vector3d(0, 0, 0)
    }
{% endif %}
{% if ros %}

    // Shown until the ROS 2 node has fully initialised.
    Rectangle {
        visible: !rosBridge.initialized
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
{% else %}

    ControlPanel {
        id: panel
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 12
        width: Math.min(420, Math.max(280, parent.width * 0.28))
        targetRobot: robotRoot
    }
{% endif %}
}
