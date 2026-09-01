// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick
import QtQuick3D
import QtQuick3D.Physics
import QtTest

import SimpleArm

Item {
    width: 400
    height: 400

    PhysicsWorld {
        id: physicsWorld
        scene: view3D.scene
    }

    View3D {
        id: view3D
        anchors.fill: parent
        PerspectiveCamera {
            z: 300
        }

        DirectionalLight {
            eulerRotation.x: -45
        }

        property SimpleArmControl ctrl: SimpleArmControl {}

        Component {
            id: armComponent
            SimpleArm {}
        }

        Node {
            id: sceneRoot
        }

        // Verify basic control/arm functionality still works when built with PHYSICS
        TestCase {
            id: controlCase
            name: "ControlWithPhysics"

            property alias ctrl: view3D.ctrl

            function test_defaultAngles() {
                compare(ctrl.shoulderPanAngle, 0.0)
                compare(ctrl.shoulderLiftAngle, 0.0)
                compare(ctrl.elbowFlexAngle, 0.0)
            }

            function test_setAngles() {
                ctrl.shoulderPanAngle = 1.5
                compare(ctrl.shoulderPanAngle, 1.5)
                ctrl.shoulderPanAngle = 0.0
            }

            function test_jointInfosCount() {
                compare(ctrl.jointInfos.length, 3)
            }
        }

        // Verify physics-specific structure of the generated SimpleArm component
        TestCase {
            id: physicsCase
            name: "PhysicsArm"

            property alias ctrl: view3D.ctrl

            function test_canInstantiate() {
                let arm = createTemporaryObject(armComponent, sceneRoot, { control: ctrl })
                verify(arm !== null)
            }

            function test_instanceScale() {
                let arm = createTemporaryObject(armComponent, sceneRoot, { control: ctrl })
                compare(arm.instanceScale, 1.0)
                arm.instanceScale = 2.0
                compare(arm.scale.x, 2.0)
            }

            function test_hasStaticRigidBodyChild() {
                let arm = createTemporaryObject(armComponent, sceneRoot, { control: ctrl })
                // The root link must be wrapped in a StaticRigidBody
                let hasStatic = false
                for (let i = 0; i < arm.children.length; ++i) {
                    if (arm.children[i] instanceof StaticRigidBody) {
                        hasStatic = true
                        break
                    }
                }
                verify(hasStatic, "Expected a StaticRigidBody among SimpleArm children")
            }

            function test_hasDynamicRigidBodyDescendants() {
                let arm = createTemporaryObject(armComponent, sceneRoot, { control: ctrl })
                // Non-root links must be wrapped in DynamicRigidBody.
                // We check the static body's subtree contains at least one DynamicRigidBody.
                function findDynamic(node) {
                    for (let i = 0; i < node.children.length; ++i) {
                        let child = node.children[i]
                        if (child instanceof DynamicRigidBody)
                            return true
                        if (findDynamic(child))
                            return true
                    }
                    return false
                }
                verify(findDynamic(arm), "Expected at least one DynamicRigidBody in SimpleArm")
            }
        }
    }
}
