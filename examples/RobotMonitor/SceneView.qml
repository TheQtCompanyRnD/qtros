// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick3D

Rectangle {
    id: root

    radius: Theme.radius
    color: Theme.card
    border.color: Theme.border
    border.width: 1

    required property MainViewModel mainViewModel
    View3D {
        id: topLeftView
        anchors.fill: parent
        anchors.margins: Theme.radius

        camera: OrthographicCamera {
            id: topDownCamera
            z: 600

            property real zoomLevel: 40
            property real yawAngle: 270

            eulerRotation: Qt.vector3d(0, 0, yawAngle)
            horizontalMagnification: zoomLevel
            verticalMagnification: zoomLevel
        }

        environment: SceneEnvironment {
            clearColor: "#181818"
            backgroundMode: SceneEnvironment.Color
            antialiasingMode: SceneEnvironment.MSAA
        }

        Node {

            id: mapFixedFrame

            GridNode {
                z: 0.01
                visible: root.mainViewModel.gridSettings.visible
                opacity: root.mainViewModel.gridSettings.opacity
                resolution: root.mainViewModel.gridSettings.cellCount
                gridStep: root.mainViewModel.gridSettings.cellWidth
            }

            OccupancyGrid {
                id: mapOccGrid
                grid: root.mainViewModel.mapGrid
                scheme: root.mainViewModel.mapSettings.colorScheme
                opacity: root.mainViewModel.mapSettings.opacity
                visible: root.mainViewModel.mapSettings.visible
            }

            OccupancyGrid {
                id: globalCostmapOccGrid

                grid: root.mainViewModel.globalCostmapGrid
                scheme: root.mainViewModel.globalCostmapSettings.colorScheme
                opacity: root.mainViewModel.globalCostmapSettings.opacity
                visible: root.mainViewModel.globalCostmapSettings.visible
            }

            ShapeNode {
                id: plan
                shapeData: root.mainViewModel.plan
            }

            Node {

                id: odometryFrame
                position: root.mainViewModel.map_odom_p
                rotation: root.mainViewModel.map_odom_q

                OccupancyGrid {
                    id: localCostmapOccGrid

                    grid: root.mainViewModel.localCostmapGrid
                    scheme: root.mainViewModel.localCostmapSettings.colorScheme
                    opacity: root.mainViewModel.localCostmapSettings.opacity
                    visible: root.mainViewModel.localCostmapSettings.visible
                }

                Node {
                    id: baseLinkFrame
                    position: root.mainViewModel.odom_base_link_p
                    rotation: root.mainViewModel.odom_base_link_q

                    Node {
                        id: shellLinkFrame
                        position: root.mainViewModel.base_link_shell_link_p
                        rotation: root.mainViewModel.base_link_shell_link_q

                        Node {
                            id: rpLidarLinkFrame
                            position: root.mainViewModel.shell_link_rplidar_link_p
                            rotation: root.mainViewModel.shell_link_rplidar_link_q
                            Node {
                                id: turtlebot4RPLidarLinkRPLidarFrame
                                position: root.mainViewModel.rplidar_link_turtlebot4_rplidar_link_rplidar_p
                                rotation: root.mainViewModel.rplidar_link_turtlebot4_rplidar_link_rplidar_q

                                LaserScan {
                                    id: laserScan
                                    instancing: root.mainViewModel.laserScanInstanceList
                                    visible: root.mainViewModel.laserScanSettings.visible
                                    opacity: root.mainViewModel.laserScanSettings.opacity
                                    color: root.mainViewModel.laserScanSettings.color
                                    pointSize: root.mainViewModel.laserScanSettings.pointSize
                                }
                            }
                        }
                    }
                }

                ShapeNode {
                    id: footprint
                    shapeData: root.mainViewModel.footprint
                }
            }
        }

        Item {
            id: arrowContainer
            width: 30
            height: 30
            visible: false
            rotation: topDownCamera.yawAngle + 90

            Rectangle {
                anchors.centerIn: parent

                width: 10
                height: 10
                radius: 5
                border.width: 2
                border.color: "#1A2332"
                color: "#2BA3B4"
            }

            Image {
                id: arrowImg
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.verticalCenter
                transformOrigin: Image.Bottom
                width: 40
                height: 60
                source: "images/arrow.svg"
                rotation: 0
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 32
            anchors.margins: 20
            radius: Theme.radius
            color: Theme.card
            border.color: Theme.border
            border.width: 1
            opacity: 0.8
            visible: mouseArea.containsMouse && !mouseArea.isDragging
                     && !arrowContainer.visible

            Text {
                anchors.centerIn: parent
                text: "Left Click + Drag: Pan    |    Ctrl + Left Click: Navigate    |    Ctrl + Right Click: Center    |    Wheel: Zoom    |    Ctrl + Wheel: Rotate"
                color: Theme.foreground
                font.pixelSize: 14
                font.bold: true
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            property bool isDragging: false
            property point lastMousePos: Qt.point(0, 0)

            onPressed: mouse => {
                           if (mouse.button === Qt.LeftButton)
                           if (mouse.modifiers & Qt.ControlModifier) {
                               arrowImg.rotation = 0
                               arrowContainer.x = mouse.x - arrowContainer.width / 2
                               arrowContainer.y = mouse.y - arrowContainer.height / 2
                               arrowContainer.visible = true
                           } else {
                               mouseArea.isDragging = true
                               lastMousePos = Qt.point(mouse.x, mouse.y)
                           }
                       }

            onPositionChanged: mouse => {
                                   if (arrowContainer.visible) {

                                       const cx = arrowContainer.x + arrowContainer.width / 2
                                       const cy = arrowContainer.y + arrowContainer.height / 2
                                       const dx = mouse.x - cx
                                       const dy = mouse.y - cy

                                       let angleDeg = Math.atan2(
                                           dy, dx) * 180 / Math.PI
                                       if (angleDeg < 0)
                                       angleDeg += 360

                                       arrowImg.rotation = angleDeg
                                   } else if (mouseArea.isDragging) {
                                       const deltaX = mouse.x - lastMousePos.x
                                       const deltaY = mouse.y - lastMousePos.y

                                       topDownCamera.position = topDownCamera.position.plus(
                                           Qt.vector3d(deltaY, deltaX, 0).times(
                                               1 / topDownCamera.zoomLevel))

                                       lastMousePos = Qt.point(mouse.x, mouse.y)
                                   }
                               }

            onReleased: mouse => {
                            if (mouse.button === Qt.LeftButton
                                && arrowContainer.visible) {
                                let scenePos = topLeftView.mapTo3DScene(
                                    Qt.vector3d(
                                        arrowContainer.x + arrowContainer.width / 2,
                                        arrowContainer.y + arrowContainer.height / 2,
                                        0))
                                let angleDeg = 360 - arrowImg.rotation
                                root.mainViewModel.navigateToPose(scenePos,
                                                                  angleDeg)
                                arrowContainer.visible = false
                            } else if (mouse.button === Qt.RightButton) {
                                let scenePos = topLeftView.mapTo3DScene(
                                    Qt.vector3d(mouse.x, mouse.y, 0))
                                topDownCamera.x = scenePos.x
                                topDownCamera.y = scenePos.y
                            }
                            mouseArea.isDragging = false
                        }

            onWheel: wheel => {
                         let modifier = wheel.angleDelta.y > 0 ? 1 : -1
                         if (wheel.modifiers & Qt.ControlModifier) {
                             topDownCamera.yawAngle += (modifier * 2)
                         } else {
                             let zoomLevel = Math.max(
                                 10, topDownCamera.zoomLevel + modifier * 5)
                             topDownCamera.zoomLevel = zoomLevel
                         }
                     }
        }
    }
}
