// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick3D

Item {
    id: root

    required property R6BotViewModel mainViewModel
    property bool showJointAxes: true

    View3D {
        id: view3D
        anchors.fill: parent

        environment: SceneEnvironment {
            clearColor: "#1b1b1b"
            backgroundMode: SceneEnvironment.Color
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.High
        }

        Node {
            id: cameraRig
            property real yawAngle: 45
            property real pitchAngle: -30
            property real distance: 2000

            position: Qt.vector3d(0, 0, 0)
            eulerRotation: Qt.vector3d(pitchAngle, yawAngle, 0)

            PerspectiveCamera {
                id: camera
                position: Qt.vector3d(0, 0, cameraRig.distance)
                clipNear: 1
                clipFar: 10000
            }
        }

        DirectionalLight {
            eulerRotation.x: -30
            eulerRotation.y: -70
            brightness: 1.0
        }

        DirectionalLight {
            eulerRotation.x: 30
            eulerRotation.y: 110
            brightness: 0.5
        }

        Model {
            source: "#Rectangle"
            y: -50
            scale: Qt.vector3d(50, 50, 50)
            eulerRotation.x: -90
            materials: PrincipledMaterial {
                baseColor: "#303030"
                metalness: 0.5
                roughness: 0.5
            }
        }
        R6BotModel {
            scale: Qt.vector3d(1000, 1000, 1000)
            eulerRotation: Qt.vector3d(-90, 0, 0)
            rosNode: root.mainViewModel.ros2Node
            visible: ready
            showJointAxes: root.showJointAxes
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: view3D
        hoverEnabled: true

        property point lastMousePos: Qt.point(0, 0)
        property bool isRotating: false

        onPressed: function (mouse) {
            lastMousePos = Qt.point(mouse.x, mouse.y)
            if (mouse.button === Qt.LeftButton) {
                isRotating = true
                mouse.accepted = true
            }
        }

        onReleased: function (mouse) {
            if (mouse.button === Qt.LeftButton) {
                isRotating = false
            }
        }

        onPositionChanged: function (mouse) {
            if (isRotating) {
                const deltaX = mouse.x - lastMousePos.x
                const deltaY = mouse.y - lastMousePos.y

                cameraRig.yawAngle += deltaX * 0.5
                cameraRig.pitchAngle += deltaY * 0.5
                cameraRig.pitchAngle = Math.max(-89,
                                                Math.min(89,
                                                         cameraRig.pitchAngle))

                lastMousePos = Qt.point(mouse.x, mouse.y)
                mouse.accepted = true
            }
        }

        onWheel: function (wheel) {
            const delta = wheel.angleDelta.y
            const zoomSpeed = cameraRig.distance * 0.001
            cameraRig.distance = Math.max(
                        100, Math.min(10000,
                                      cameraRig.distance - delta * zoomSpeed))
            wheel.accepted = true
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 32
        color: "#cc202020"
        visible: mouseArea.containsMouse && !mouseArea.isRotating

        Row {
            anchors.centerIn: parent
            spacing: 20
            Text {
                text: "Left Drag: Rotate | Wheel: Zoom"
                color: "#e0e0e0"
                font.pixelSize: 14
                font.bold: true
            }
        }
    }
}
