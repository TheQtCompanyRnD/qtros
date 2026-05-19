import QtQuick
import QtQuick.Window
{% if ros %}
import QtRos2.Core as Ros2
{% endif %}

import QtQuick3D
import QtQuick3D.Helpers

Window {
    width: 1920
    height: 1080
    visible: true
    title: qsTr("{{ base_name }}{% if ros %} ROS Preview{% endif %}")

{% if ros %}
    // Initialises the ROS 2 context before any ROS2Node is created.
    // Add nodeArgs here for remapping or other --ros-args options, e.g.:
    //   nodeArgs: ["--ros-args", "--remap", "/joint_states:=/robot/joint_states"]
    Ros2.Context {}

    PreviewScene {
        anchors.fill: parent
    }
}
{% else %}
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
{% endif %}
