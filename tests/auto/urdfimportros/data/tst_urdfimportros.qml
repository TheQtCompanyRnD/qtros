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

        Component {
            id: bridgeComponent
            RosBridge {}
        }

        Component {
            id: armComponent
            SimpleArm {}
        }

        Node {
            id: sceneRoot
        }

        // Tests for the generated RosBridge component
        TestCase {
            id: rosBridgeCase
            name: "RosBridgeImport"

            // Separate ctrl+bridge kept alive for the lifetime of the TestCase
            property SimpleArmControl bridgeCtrl: SimpleArmControl {}
            property var bridge: RosBridge { control: rosBridgeCase.bridgeCtrl }

            function test_canInstantiate() {
                verify(bridge !== null)
            }

            function test_jointStateTopic_default() {
                compare(bridge.jointStateTopic, "/joint_states")
            }

            function test_jointStateTopic_settable() {
                bridge.jointStateTopic = "/my_robot/joint_states"
                compare(bridge.jointStateTopic, "/my_robot/joint_states")
            }

            function test_jointRosNameMap_keys() {
                let map = bridge._jointRosNameMap
                verify(map.hasOwnProperty("shoulder_pan"))
                verify(map.hasOwnProperty("shoulder_lift"))
                verify(map.hasOwnProperty("elbow_flex"))
            }

            function test_jointRosNameMap_values() {
                let map = bridge._jointRosNameMap
                compare(map["shoulder_pan"],  "shoulderPanAngle")
                compare(map["shoulder_lift"], "shoulderLiftAngle")
                compare(map["elbow_flex"],    "elbowFlexAngle")
            }

            function test_initialized_property_readable() {
                compare(typeof bridge.initialized, "boolean")
            }
        }

        // Verify SimpleArm + SimpleArmControl still work when module built with ROS_BRIDGE
        TestCase {
            id: simpleArmWithBridgeCase
            name: "SimpleArmWithBridge"

            property alias ctrl: view3D.ctrl

            function test_controlDefaultAngles() {
                compare(ctrl.shoulderPanAngle, 0.0)
                compare(ctrl.shoulderLiftAngle, 0.0)
                compare(ctrl.elbowFlexAngle, 0.0)
            }

            function test_controlJointInfosCount() {
                compare(ctrl.jointInfos.length, 3)
            }

            function test_armCanInstantiate() {
                let arm = createTemporaryObject(armComponent, sceneRoot, { control: ctrl })
                verify(arm !== null)
            }

            function test_armInstanceScale() {
                let arm = createTemporaryObject(armComponent, sceneRoot, { control: ctrl })
                compare(arm.instanceScale, 1.0)
                arm.instanceScale = 2.0
                compare(arm.scale.x, 2.0)
            }
        }
    }
}
