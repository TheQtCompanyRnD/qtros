// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick
import QtQuick3D
import QtTest
import QtRos2.Core as Ros2
import QtRos2.GeometryMsgs as Geom
import QtRos2.Transforms
import QtRos2.Quick3D

// The test latches a small TF tree on its own node's tf_static, and checks
// where FrameNodes end up:
//
//   world --(1, 0, 0)--> a --(0, 2, 0), 90 deg about Z--> b --(0, 0, 3)--> c
//
// The node has its own namespace, so other TF traffic on the machine can't
// interfere.
TestCase {
    id: tc
    name: "FrameNode"
    when: windowShown

    readonly property real s: Math.SQRT1_2 // sin and cos of 45 degrees

    // Typed properties: a JS array of plain objects doesn't convert to
    // list<transformStamped> element by element.
    property Geom.transformStamped worldToA: ({
        header: { frameId: "world" }, childFrameId: "a",
        transform: { translation: { x: 1, y: 0, z: 0 }, rotation: { x: 0, y: 0, z: 0, w: 1 } }
    })
    property Geom.transformStamped aToB: ({
        header: { frameId: "a" }, childFrameId: "b",
        transform: { translation: { x: 0, y: 2, z: 0 }, rotation: { x: 0, y: 0, z: s, w: s } }
    })
    property Geom.transformStamped bToC: ({
        header: { frameId: "b" }, childFrameId: "c",
        transform: { translation: { x: 0, y: 0, z: 3 }, rotation: { x: 0, y: 0, z: 0, w: 1 } }
    })

    Ros2.Node {
        id: rosNode
        nodeName: "tst_framenode"
        nodeNamespace: "/tst_framenode"

        StaticTransformBroadcaster {
            transforms: [tc.worldToA, tc.aToB, tc.bToC]
        }

        FrameTransformer { id: tf }
    }

    View3D {
        width: 100
        height: 100

        FrameNode {
            id: worldNode
            frame: "world"
            rosNode: rosNode
            position: Qt.vector3d(5, 0, 0) // the root stays where it's put

            FrameNode {
                id: aNode
                frame: "a"

                Node {
                    scale: Qt.vector3d(2, 2, 2) // presentation only

                    FrameNode {
                        id: bNode
                        frame: "b"
                    }
                }
            }

            // Not in the scene: "a" and "b"; TF composes world -> a -> b -> c.
            FrameNode {
                id: cNode
                frame: "c"
            }

            FrameNode {
                id: overrideNode
                frame: "c"
                parentFrame: "b"
            }

            FrameNode {
                id: missingNode
                frame: "nonexistent"
                position: Qt.vector3d(7, 8, 9)
            }
        }
    }

    function compareVector(actual, expected, msg) {
        verify(actual.fuzzyEquals(expected, 1e-5),
               `${msg}: got ${actual}, expected ${expected}`)
    }

    function compareRotation(actual, expected, msg) {
        // q and -q are the same rotation
        const d = Math.abs(actual.dotProduct(expected))
        verify(Math.abs(d - 1) < 1e-5, `${msg}: got ${actual}, expected ${expected}`)
    }

    function initTestCase() {
        tryVerify(() => rosNode.initialized, 5000, "node failed to initialize")
        tryVerify(() => cNode.valid, 5000, "tf_static never arrived")
    }

    function test_root() {
        verify(worldNode.valid)
        compare(worldNode.parentFrame, "")
        compareVector(worldNode.position, Qt.vector3d(5, 0, 0), "root position")
    }

    function test_inheritsFromAncestor() {
        compare(aNode.parentFrame, "world")
        compare(aNode.rosNode, rosNode)
        verify(aNode.valid)
        compareVector(aNode.position, Qt.vector3d(1, 0, 0), "a in world")
        compareRotation(aNode.rotation, Qt.quaternion(1, 0, 0, 0), "a in world")
    }

    function test_looksPastPlainNodes() {
        compare(bNode.parentFrame, "a")
        compare(bNode.rosNode, rosNode)
        verify(bNode.valid)
        compareVector(bNode.position, Qt.vector3d(0, 2, 0), "b in a")
        compareRotation(bNode.rotation, Qt.quaternion(s, 0, 0, s), "b in a")
    }

    function test_composesFramesNotInScene() {
        compareVector(cNode.position, Qt.vector3d(1, 2, 3), "c in world")
        compareRotation(cNode.rotation, Qt.quaternion(s, 0, 0, s), "c in world")
    }

    function test_explicitParentFrame() {
        compare(overrideNode.parentFrame, "b")
        compareVector(overrideNode.position, Qt.vector3d(0, 0, 3), "c in b")

        overrideNode.parentFrame = undefined // back to the ancestor's frame
        compare(overrideNode.parentFrame, "world")
        compareVector(overrideNode.position, Qt.vector3d(1, 2, 3), "c in world")

        overrideNode.parentFrame = "b"
        compareVector(overrideNode.position, Qt.vector3d(0, 0, 3), "c in b again")
    }

    function test_frameChange() {
        cNode.frame = "a"
        compareVector(cNode.position, Qt.vector3d(1, 0, 0), "a in world")
        cNode.frame = "c"
        compareVector(cNode.position, Qt.vector3d(1, 2, 3), "c in world again")
    }

    function test_ancestorFrameChange() {
        // bNode inherits its parentFrame from aNode
        aNode.frame = "world"
        compare(bNode.parentFrame, "world")
        tryVerify(() => bNode.position.fuzzyEquals(Qt.vector3d(1, 2, 0), 1e-5),
                  1000, `b in world: got ${bNode.position}`)
        aNode.frame = "a"
        compare(bNode.parentFrame, "a")
        compareVector(bNode.position, Qt.vector3d(0, 2, 0), "b in a again")
    }

    function test_missingTransform() {
        verify(!missingNode.valid)
        compareVector(missingNode.position, Qt.vector3d(7, 8, 9), "left in place")
    }

    function test_frameTransformerSharesTheTree() {
        verify(tf.canTransform("world", "c"))
        const t = tf.lookupTransform("world", "c")
        compare(t.childFrameId, "c")
        compare(t.transform.translation.y, 2)
    }
}
