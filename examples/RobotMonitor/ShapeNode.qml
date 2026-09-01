// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick.Shapes
import QtQuick3D
import QtQuick3D.Helpers

Model {
    id: shapeModel

    required property ShapeData shapeData

    position: shapeModel.shapeData.center
    visible: shapeModel.shapeData.visible
    opacity: shapeModel.shapeData.opacity

    // In Qt 6.9+ we could use:
    // PlaneGeometry {
    //         width: shapeModel.shapeData.width
    //         height: shapeModel.shapeData.height
    //         plane: PlaneGeometry.XY
    //         mirrored: true
    //     }
    geometry: ProceduralMesh {
        property real w2: shapeModel.shapeData.width / 2
        property real h2: shapeModel.shapeData.height / 2

        positions: [Qt.vector3d(-w2, -h2, 0), // Index 0: Bottom Left
            Qt.vector3d(w2, -h2, 0), // Index 1: Bottom Right
            Qt.vector3d(w2, h2, 0), // Index 2: Top Right
            Qt.vector3d(-w2, h2, 0) // Index 3: Top Left
        ]

        // Vertical Flip (mirrored: true)
        // Standard: (0,0), (1,0), (1,1), (0,1)
        // Vertically Mirrored: (0,1), (1,1), (1,0), (0,0)
        uv0s: [Qt.vector2d(0, 1), // Bottom Left (V is now 1)
            Qt.vector2d(1, 1), // Bottom Right (V is now 1)
            Qt.vector2d(1, 0), // Top Right (V is now 0)
            Qt.vector2d(0, 0) // Top Left (V is now 0)
        ]

        indexes: [0, 1, 2, 0, 2, 3]

        normals: [Qt.vector3d(0, 0, 1), Qt.vector3d(0, 0, 1), Qt.vector3d(
                0, 0, 1), Qt.vector3d(0, 0, 1)]
    }

    materials: PrincipledMaterial {
        alphaMode: PrincipledMaterial.Blend
        lighting: PrincipledMaterial.NoLighting
        cullMode: Material.NoCulling
        baseColorMap: Texture {
            minFilter: Texture.Linear
            magFilter: Texture.Linear
            tilingModeHorizontal: Texture.ClampToEdge
            tilingModeVertical: Texture.ClampToEdge
            sourceItem: Item {
                width: shapeModel.shapeData.textureWidth
                height: shapeModel.shapeData.textureHeight
                opacity: shapeModel.shapeData.opacity
                Shape {
                    anchors.centerIn: parent
                    preferredRendererType: Shape.CurveRenderer
                    antialiasing: true
                    ShapePath {
                        strokeColor: shapeModel.shapeData.strokeColor
                        strokeWidth: shapeModel.shapeData.strokeWidth
                        fillColor: shapeModel.shapeData.fillColor
                        pathHints: ShapePath.PathLinear
                        joinStyle: ShapePath.MiterJoin
                        PathPolyline {
                            path: shapeModel.shapeData.shapePoints
                        }
                    }
                }
            }
        }
    }
}
