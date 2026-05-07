// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: BSD-3-Clause
import QtQuick
import QtQuick.Window

import QtQuick3D

import SimpleArm

Window {
    width: 1920
    height: 1080
    visible: true
    title: qsTr("URDF Robot Arm Test")

    SimpleArmControl {
        id: armControl
    }

    View3D {
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
