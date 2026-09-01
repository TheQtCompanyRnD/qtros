// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick3D

Node {
    id: r6botRoot

    property bool showJointAxes: true

    property alias worldPosition: worldNode.position
    property alias worldRotation: worldNode.rotation
    property alias baseLinkPosition: baseLinkNode.position
    property alias baseLinkRotation: baseLinkNode.rotation
    property alias link1Position: link1Node.position
    property alias link1Rotation: link1Node.rotation
    property alias link2Position: link2Node.position
    property alias link2Rotation: link2Node.rotation
    property alias link3Position: link3Node.position
    property alias link3Rotation: link3Node.rotation
    property alias link4Position: link4Node.position
    property alias link4Rotation: link4Node.rotation
    property alias link5Position: link5Node.position
    property alias link5Rotation: link5Node.rotation
    property alias link6Position: link6Node.position
    property alias link6Rotation: link6Node.rotation
    property alias ftFramePosition: ftFrameNode.position
    property alias ftFrameRotation: ftFrameNode.rotation
    property alias tool0Position: tool0Node.position
    property alias tool0Rotation: tool0Node.rotation

    Node {
        id: worldNode

        Node {
            id: baseLinkNode
            // Joint: fixed, axis: [0.0, 0.0, 1.0]
            position: Qt.vector3d(0.0, 0.0, 0.0)

            JointAxes {
                visible: r6botRoot.showJointAxes
            }

            Node {
                id: baseLinkVisual

                Link_0 {
                    // Cancel Y-UP balsam rotation
                    rotation: Qt.quaternion(0.7071068, 0.7071068, 0, 0)
                }
            }

            Node {
                id: link1Node
                // Joint: revolute, axis: [0.0, 0.0, 1.0]
                position: Qt.vector3d(0.0, 0.0, 0.061584)

                JointAxes {
                    visible: r6botRoot.showJointAxes
                }

                Node {
                    id: link1Visual

                    Link_1 {
                        // URDF <visual> origin offset within link_1, plus
                        // cancel Y-UP balsam rotation
                        position: Qt.vector3d(0.0, 0.0, -0.182)
                        rotation: Qt.quaternion(0.7071068, 0.7071068, 0, 0)
                    }
                }

                Node {
                    id: link2Node
                    // Joint: revolute, axis: [0.0, 0.0, 1.0]
                    position: Qt.vector3d(-0.101717, 0.0, 0.182284)
                    rotation: Qt.quaternion(0.6830127018922193,
                                            -0.18301270189221935,
                                            -0.6830127018922192,
                                            0.18301270189221935)

                    JointAxes {
                        visible: r6botRoot.showJointAxes
                    }

                    Node {
                        id: link2Visual

                        Link_2 {
                            // URDF <visual> origin offset within link_2, plus
                            // cancel Y-UP balsam rotation
                            position: Qt.vector3d(0.0, 0.0, -0.168)
                            rotation: Qt.quaternion(0.7071068, 0.7071068, 0, 0)
                        }
                    }

                    Node {
                        id: link3Node
                        // Joint: revolute, axis: [0.0, 0.0, 1.0]
                        position: Qt.vector3d(0.685682, 0.0, 0.041861)
                        rotation: Qt.quaternion(-4.329780281177466e-17,
                                                -0.7071067811865476,
                                                -0.7071067811865475,
                                                4.329780281177467e-17)

                        JointAxes {
                            visible: r6botRoot.showJointAxes
                        }

                        Node {
                            id: link3Visual

                            Link_3 {
                                // URDF <visual> origin offset within link_3, plus
                                // cancel Y-UP balsam rotation
                                position: Qt.vector3d(0.0, 0.0, -0.144)
                                rotation: Qt.quaternion(0.7071068,
                                                        0.7071068, 0, 0)
                            }
                        }

                        Node {
                            id: link4Node
                            // Joint: revolute, axis: [0.0, 0.0, 1.0]
                            position: Qt.vector3d(0.518777, 0.0, 0.067458)
                            rotation: Qt.quaternion(-1.5848095757158815e-17,
                                                    -0.9659258262890683,
                                                    -0.25881904510252063,
                                                    5.914589856893349e-17)

                            JointAxes {
                                visible: r6botRoot.showJointAxes
                            }

                            Node {
                                id: link4Visual

                                Link_4 {
                                    // URDF <visual> origin offset within link_4, plus
                                    // cancel Y-UP balsam rotation
                                    position: Qt.vector3d(0.0, 0.0, 0.077)
                                    rotation: Qt.quaternion(0.7071068,
                                                            0.7071068, 0, 0)
                                }
                            }

                            Node {
                                id: link5Node
                                // Joint: revolute, axis: [0.0, 0.0, 1.0]
                                position: Qt.vector3d(0.112654, 0.0, 0.110903)
                                rotation: Qt.quaternion(0.49999999999999994,
                                                        -0.49999999999999994,
                                                        0.5000000000000001,
                                                        -0.49999999999999994)

                                JointAxes {
                                    visible: r6botRoot.showJointAxes
                                }

                                Node {
                                    id: link5Visual

                                    Link_5 {
                                        // URDF <visual> origin offset within link_5, plus
                                        // cancel Y-UP balsam rotation
                                        position: Qt.vector3d(0.0, 0.0, 0.113)
                                        rotation: Qt.quaternion(0.7071068,
                                                                0.7071068, 0, 0)
                                    }
                                }

                                Node {
                                    id: link6Node
                                    // Joint: revolute, axis: [0.0, 0.0, 1.0]
                                    position: Qt.vector3d(-0.085976,
                                                          0.0, 0.133436)
                                    rotation: Qt.quaternion(
                                                  0.7071067811865476, 0.0,
                                                  -0.7071067811865475, 0.0)

                                    JointAxes {
                                        visible: r6botRoot.showJointAxes
                                    }

                                    Node {
                                        id: link6Visual

                                        Link_6 {
                                            // URDF <visual> origin offset within link_6, plus
                                            // cancel Y-UP balsam rotation
                                            position: Qt.vector3d(0.0, 0.0, 0.086)
                                            rotation: Qt.quaternion(0.7071068,
                                                                    0.7071068,
                                                                    0, 0)
                                        }
                                    }

                                    Node {
                                        id: ftFrameNode
                                        // Joint: fixed
                                        position: Qt.vector3d(0.0, 0.0, 0.0)

                                        Node {
                                            id: tool0Node
                                            // Joint: fixed
                                            position: Qt.vector3d(0.0,
                                                                  0.0, 0.185)

                                            JointAxes {
                                                visible: r6botRoot.showJointAxes
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
