// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick3D

Node {
    id: node

    // Resources
    PrincipledMaterial {
        id: grey_material
        objectName: "grey"
        baseColor: "#ffa7a7a7"
        indexOfRefraction: 1.4500000476837158
    }

    // Nodes:
    Node {
        id: scene
        objectName: "Scene"
        rotation: Qt.quaternion(0.707107, -0.707107, 0, 0)
        Model {
            id: base
            objectName: "base"
            source: "meshes/base_001_mesh.mesh"
            materials: [
                grey_material
            ]
        }
    }

    // Animations:
}
