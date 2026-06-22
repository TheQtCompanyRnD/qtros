import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
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
{% if physics %}

        // Default static ground plane. Gives the robot a surface to stand on
        // and serves as the collider that robots/objects rest against.
        StaticRigidBody {
            collisionShapes: [
                BoxShape {
                    // Thick collider so fast-falling dynamic bodies cannot tunnel
                    // through it; its top surface sits at y = 0 to match the visual
                    // ground Model below.
                    readonly property real groundThickness: 1000
                    extents: Qt.vector3d(10000, groundThickness / 2, 10000)
                    position: Qt.vector3d(0, -50, 0)
                }
            ]

            Model {
                source: "#Rectangle"
                eulerRotation.x: -90
                scale: Qt.vector3d(100, 100, 100)
                materials: [
                    PrincipledMaterial {
                        baseColor: "#4caf50"
                        roughness: 1.0
                    }
                ]
            }
        }
{% endif %}
    }

    // Move the whole model up/down along the vertical (scene Y) axis.
    Pane {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 12

        RowLayout {
            Label { text: qsTr("Height") }
            TextField {
                implicitWidth: 90
                text: robotRoot.y.toFixed(1)
                validator: DoubleValidator {}
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                onEditingFinished: robotRoot.y = parseFloat(text)
            }
        }
    }
{% if physics %}

    PhysicsWorld {
        id: physicsWorld
        scene: view3D.scene
        running: false
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
{% if physics %}
        physicsWorld: physicsWorld
{% endif %}
    }
{% endif %}
}
