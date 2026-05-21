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
            visible: root.mainViewModel.tfBuffer.transformsReady
            showJointAxes: root.showJointAxes
            baseLinkPosition: root.mainViewModel.tfBuffer.world_base_link_p
            baseLinkRotation: root.mainViewModel.tfBuffer.world_base_link_q
            link1Position: root.mainViewModel.tfBuffer.base_link_link_1_p
            link1Rotation: root.mainViewModel.tfBuffer.base_link_link_1_q
            link2Position: root.mainViewModel.tfBuffer.link_1_link_2_p
            link2Rotation: root.mainViewModel.tfBuffer.link_1_link_2_q
            link3Position: root.mainViewModel.tfBuffer.link_2_link_3_p
            link3Rotation: root.mainViewModel.tfBuffer.link_2_link_3_q
            link4Position: root.mainViewModel.tfBuffer.link_3_link_4_p
            link4Rotation: root.mainViewModel.tfBuffer.link_3_link_4_q
            link5Position: root.mainViewModel.tfBuffer.link_4_link_5_p
            link5Rotation: root.mainViewModel.tfBuffer.link_4_link_5_q
            link6Position: root.mainViewModel.tfBuffer.link_5_link_6_p
            link6Rotation: root.mainViewModel.tfBuffer.link_5_link_6_q
            ftFramePosition: root.mainViewModel.tfBuffer.link_6_ft_frame_p
            ftFrameRotation: root.mainViewModel.tfBuffer.link_6_ft_frame_q
            tool0Position: root.mainViewModel.tfBuffer.ft_frame_tool0_p
            tool0Rotation: root.mainViewModel.tfBuffer.ft_frame_tool0_q
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
