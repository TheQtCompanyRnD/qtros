// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick
import QtQuick3D
import QtTest

import SimpleArm

Item {
    width: 400
    height: 400

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

        TestCase {
            id: testCase
            name: "UrdfImport"

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

                ctrl.shoulderLiftAngle = -0.5
                compare(ctrl.shoulderLiftAngle, -0.5)
                ctrl.shoulderLiftAngle = 0.0
            }

            function test_jointInfosCount() {
                compare(ctrl.jointInfos.length, 3)
            }

            function test_jointInfosNames() {
                compare(ctrl.jointInfos[0].name, "shoulderPanAngle")
                compare(ctrl.jointInfos[1].name, "shoulderLiftAngle")
                compare(ctrl.jointInfos[2].name, "elbowFlexAngle")
            }

            function test_jointLimits() {
                // shoulder_pan: -pi .. +pi
                fuzzyCompare(ctrl.jointInfos[0].lower, -3.14159, 0.001)
                fuzzyCompare(ctrl.jointInfos[0].upper,  3.14159, 0.001)
                // shoulder_lift: -pi/2 .. +pi/2
                fuzzyCompare(ctrl.jointInfos[1].lower, -1.5708, 0.001)
                fuzzyCompare(ctrl.jointInfos[1].upper,  1.5708, 0.001)
                // elbow_flex: -pi/2 .. +pi/2
                fuzzyCompare(ctrl.jointInfos[2].lower, -1.5708, 0.001)
                fuzzyCompare(ctrl.jointInfos[2].upper,  1.5708, 0.001)
            }
        }

        Component {
            id: armComponent
            SimpleArm {}
        }

        Node {
            id: simpleArmRoot
        }

        TestCase {
            id: simpleArmCase
            name: "SimpleArm"

            property alias ctrl: view3D.ctrl

            function test_canInstantiate() {
                let arm = createTemporaryObject(armComponent, simpleArmRoot, { control: ctrl })
                verify(arm !== null)
            }

            function test_defaultProperties() {
                let arm = createTemporaryObject(armComponent, simpleArmRoot, { control: ctrl })
                compare(arm.sceneUnitsPerMeter, 100.0)
                compare(arm.instanceScale, 1.0)
            }

            function test_instanceScaleBinding() {
                let arm = createTemporaryObject(armComponent, simpleArmRoot, { control: ctrl })
                arm.instanceScale = 2.0
                compare(arm.scale.x, 2.0)
                compare(arm.scale.y, 2.0)
                compare(arm.scale.z, 2.0)
            }

            function test_toEulerAngle() {
                let arm = createTemporaryObject(armComponent, simpleArmRoot, { control: ctrl })
                compare(arm.toEulerAngle(0), 0.0)
                fuzzyCompare(arm.toEulerAngle(Math.PI), 180.0, 0.001)
                fuzzyCompare(arm.toEulerAngle(Math.PI / 2), 90.0, 0.001)
            }

            function test_linkPositionAliases() {
                let arm = createTemporaryObject(armComponent, simpleArmRoot, { control: ctrl })
                // Aliases must exist and return a vector3d without crashing.
                verify(typeof arm.baseLinkPosition === "object")
                verify(typeof arm.upperArmLinkPosition === "object")
                verify(typeof arm.forearmLinkPosition === "object")
                verify(typeof arm.wristLinkPosition === "object")
            }
        }
    }
}
