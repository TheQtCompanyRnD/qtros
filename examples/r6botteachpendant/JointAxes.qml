// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick3D

Node {
    id: root

    property real axisLength: 0.002
    property real axisRadius: 0.0001

    // The built-in #Cylinder is 100 units high (Y: -50 to +50).
    // Setting pivot.y to -50 moves the origin to the bottom cap.
    property vector3d cylinderPivot: Qt.vector3d(0, -50, 0)

    eulerRotation: Qt.vector3d(90, 0, 0)

    Model {
        source: "#Cylinder"
        pivot: root.cylinderPivot
        position: Qt.vector3d(0, 0, 0)

        eulerRotation: Qt.vector3d(0, 0, -90)

        scale: Qt.vector3d(root.axisRadius, root.axisLength, root.axisRadius)
        materials: PrincipledMaterial {
            baseColor: "#ff0000"
            lighting: PrincipledMaterial.NoLighting
        }
    }

    Model {
        source: "#Cylinder"
        pivot: root.cylinderPivot
        position: Qt.vector3d(0, 0, 0)

        eulerRotation: Qt.vector3d(0, 0, 0)

        scale: Qt.vector3d(root.axisRadius, root.axisLength, root.axisRadius)
        materials: PrincipledMaterial {
            baseColor: "#0000ff"
            lighting: PrincipledMaterial.NoLighting
        }
    }

    Model {
        source: "#Cylinder"
        pivot: root.cylinderPivot
        position: Qt.vector3d(0, 0, 0)

        eulerRotation: Qt.vector3d(-90, 0, 0)

        scale: Qt.vector3d(root.axisRadius, root.axisLength, root.axisRadius)
        materials: PrincipledMaterial {
            baseColor: "#00ff00"
            lighting: PrincipledMaterial.NoLighting
        }
    }
}
