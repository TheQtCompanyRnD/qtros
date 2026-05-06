import QtQuick
import QtQuick.Window

import QtQuick3D
import QtQuick3D.Helpers

Window {
    width: 1920
    height: 1080
    visible: true
    title: qsTr("{{ base_name }}")

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
                z: 500
            }

            DirectionalLight {
                id: directionalLight
                eulerRotation: Qt.vector3d(-30, 30, 0)
            }
        }

        {{ base_name }} {
            id: robotRoot
            control: {{ base_name }}Control {}
        }
    }

    OrbitCameraController {
        origin: cameraNode
        camera: sceneCamera
    }
}
