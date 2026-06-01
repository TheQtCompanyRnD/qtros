// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
import QtQuick
import QtQuick.Window

import QtQuick3D
import QtQuick3D.Physics

import SimpleArm

Window {
    width: 1920
    height: 1080
    visible: true
    title: qsTr("URDF Robot Arm Test")

    PhysicsWorld {
	running: true
	forceDebugDraw: true
	scene: view.scene
    }

    SimpleArmControl {
        id: armControl
    }

    View3D {
        id: view
        anchors.fill: parent
        camera: PerspectiveCamera {
            position: Qt.vector3d(0, 0, 300)
        }

	DirectionalLight {}

        SimpleArm {
            control: armControl
        }
    }
}
