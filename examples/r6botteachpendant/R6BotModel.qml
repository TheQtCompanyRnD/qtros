// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick3D
import QtRos2.Quick3D

Node {
    id: r6botRoot

    property bool showJointAxes: true

    // The ROS node whose TF tree drives the arm; inherited by every FrameNode
    // below. Each FrameNode follows its link's frame relative to the enclosing
    // one, as robot_state_publisher computes it from /joint_states. The
    // positions and rotations written below are the URDF rest pose, shown
    // until TF has placed the links.
    property alias rosNode: worldNode.rosNode

    // True once TF has placed every link.
    readonly property bool ready: [baseLinkNode, link1Node, link2Node, link3Node, link4Node,
                                   link5Node, link6Node, ftFrameNode, tool0Node].every(n => n.valid)

    FrameNode {
        id: worldNode
        frame: "world"

        FrameNode {
            id: baseLinkNode
            frame: "base_link"
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

            FrameNode {
                id: link1Node
                frame: "link_1"
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

                FrameNode {
                    id: link2Node
                    frame: "link_2"
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

                    FrameNode {
                        id: link3Node
                        frame: "link_3"
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

                        FrameNode {
                            id: link4Node
                            frame: "link_4"
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

                            FrameNode {
                                id: link5Node
                                frame: "link_5"
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

                                FrameNode {
                                    id: link6Node
                                    frame: "link_6"
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

                                    FrameNode {
                                        id: ftFrameNode
                                        frame: "ft_frame"
                                        // Joint: fixed
                                        position: Qt.vector3d(0.0, 0.0, 0.0)

                                        FrameNode {
                                            id: tool0Node
                                            frame: "tool0"
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
