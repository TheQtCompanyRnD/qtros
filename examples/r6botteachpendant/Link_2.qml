// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick3D

Node {
    id: node

    // Resources
    PrincipledMaterial {
        id: black_material
        objectName: "black"
        baseColor: "#ff393939"
        indexOfRefraction: 1.4500000476837158
    }
    PrincipledMaterial {
        id: material_002_material
        objectName: "Material.002"
        baseColor: "#ff171370"
        indexOfRefraction: 1.4500000476837158
    }

    // Nodes:
    Node {
        id: scene
        objectName: "Scene"
        rotation: Qt.quaternion(0.707107, -0.707107, 0, 0)
        Model {
            id: link_2
            objectName: "link_2"
            source: "meshes/link_2_mesh.mesh"
            materials: [
                black_material,
                material_002_material
            ]
        }
    }

    // Animations:
}
