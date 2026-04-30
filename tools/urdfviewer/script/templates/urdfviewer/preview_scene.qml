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
            control: {{ base_name }}Control {}
        }
    }
{% if physics %}

    PhysicsWorld {
        scene: view3D.scene
        gravity: Qt.vector3d(0, 0, 0)
    }
{% endif %}

    ControlPanel {
        id: panel
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 12
        width: Math.min(420, Math.max(280, parent.width * 0.28))
        targetRobot: robotRoot
    }
}
