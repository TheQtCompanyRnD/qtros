// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick.Window
import QtQuick.Controls

import QtQuick3D
import QtQuick3D.Physics

import SimpleArm

Window {
    id: window
    width: 1280
    height: 720
    visible: true
    title: qsTr("Robot Arm Collision")

    property bool animate: false

    PhysicsWorld {
        id: physicsWorld
        scene: view3d.scene
        running: true
    }

    SimpleArmControl {
        id: armControl
        // Make the robot links report overlaps so the obstacle TriggerBody can
        // detect when the arm sweeps into it.
        sendTriggerReports: true
    }

    RosBridge {
	id: rosBridge
	control: armControl
	// If we're animating drop the joint messages.
	// This also make it where the user can manually control
	// the robot arm using the joint publisher
	// $> ros2 launch simple_arm.launch.py 
	processMessages: !animate
    }

    View3D {
        id: view3d
        anchors.fill: parent

        environment: SceneEnvironment {
            backgroundMode: SceneEnvironment.Color
            clearColor: "#202024"
        }

        camera: PerspectiveCamera {
            position: Qt.vector3d(0, 70, 120)
            eulerRotation.x: -18
        }

        DirectionalLight {
            eulerRotation.x: -40
            eulerRotation.y: -30
        }

        Node {
            id: armSpin
            NumberAnimation on eulerRotation.y {
                from: 0
                to: 360
                duration: 5000
                loops: Animation.Infinite
                running: animate
            }
            SimpleArm {
                id: arm
                control: armControl
            }
        }

        // Keep the forearm reaching outward so the spinning arm sweeps
	// through the obstacle once per revolution.
        SequentialAnimation {
            loops: Animation.Infinite
            running: animate
            PropertyAnimation {
                target: armControl
                property: "shoulderLiftAngle"
                duration: 2500
                from: 0.9
                to: armControl.jointInfos[1].upper
            }
            PropertyAnimation {
                target: armControl
                property: "shoulderLiftAngle"
                duration: 2500
                from: armControl.jointInfos[1].upper
                to: 0.9
            }
        }

        // Static obstacle in the arm sweep path. As a TriggerBody it does not block
        // the (kinematic) arm; it just reports overlap so we can react. The overlaps
        // counter keeps the box red while any link is inside it.
        TriggerBody {
            id: obstacle
            position: Qt.vector3d(22, 40, 0)

            property int overlaps: 0

            collisionShapes: BoxShape {
                id: obstacleShape
                extents: Qt.vector3d(18, 18, 18)
            }

            onBodyEntered: {
                obstacle.overlaps++
                banner.flash()
            }
            onBodyExited: obstacle.overlaps = Math.max(0, obstacle.overlaps - 1)

            Model {
                source: "#Cube"
                scale: Qt.vector3d(obstacleShape.extents.x / 100,
                                   obstacleShape.extents.y / 100,
                                   obstacleShape.extents.z / 100)
                materials: PrincipledMaterial {
                    baseColor: obstacle.overlaps > 0 ? "red" : "#cccccc"
                }
            }
        }
    }

    // Banner shown for a second whenever a new collision is detected.
    Text {
        id: banner
        text: qsTr("Collision detected")
        color: "red"
        font.pixelSize: 36
        font.bold: true
        anchors.horizontalCenter: parent.horizontalCenter
        y: 40
        visible: false

        function flash() {
            visible = true
            hideTimer.restart()
        }
        Timer {
            id: hideTimer
            interval: 1000
            onTriggered: banner.visible = false
        }
    }

    // Small control panel: toggle the demo animation. When unchecked the RosBridge
    // drives the joints from incoming /joint_states messages instead.
    Rectangle {
        id: controlPanel
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 12
        width: animateCheck.implicitWidth + 24
        height: animateCheck.implicitHeight + 24
        radius: 6
        color: Qt.rgba(0, 0, 0, 0.5)

        CheckBox {
            id: animateCheck
            anchors.centerIn: parent
            text: qsTr("Animate")
            checked: window.animate
            onToggled: window.animate = checked
            palette.windowText: "white"
        }
    }
}
