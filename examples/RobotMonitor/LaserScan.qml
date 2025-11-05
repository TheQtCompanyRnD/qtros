import QtQuick
import QtQuick3D
import QtQuick3D.Helpers

Model {
    id: laserScanModel

    property real pointSize: 0.05 // in m
    property alias color: circleRect.color

    // In Qt 6.9+ we could use:
    // PlaneGeometry {
    //     width: laserScanModel.pointSize
    //     height: laserScanModel.pointSize
    //     plane: PlaneGeometry.XY
    // }
    geometry: ProceduralMesh {
        // Calculate half-size for centering
        property real s2: laserScanModel.pointSize / 2

        // Vertices for an XY plane centered at (0,0,0)
        positions: [Qt.vector3d(-s2, -s2, 0), // Index 0: Bottom Left
            Qt.vector3d(s2, -s2, 0), // Index 1: Bottom Right
            Qt.vector3d(s2, s2, 0), // Index 2: Top Right
            Qt.vector3d(-s2, s2, 0) // Index 3: Top Left
        ]

        // Standard UV Mapping (No Mirroring)
        // Bottom-Left is (0,0), Top-Right is (1,1)
        uv0s: [Qt.vector2d(0, 0), // Bottom Left
            Qt.vector2d(1, 0), // Bottom Right
            Qt.vector2d(1, 1), // Top Right
            Qt.vector2d(0, 1) // Top Left
        ]

        // Two triangles (Counter-Clockwise winding)
        indexes: [0, 1, 2, 0, 2, 3]

        // Normal pointing towards +Z (facing the viewer)
        normals: [Qt.vector3d(0, 0, 1), Qt.vector3d(0, 0, 1), Qt.vector3d(
                0, 0, 1), Qt.vector3d(0, 0, 1)]
    }

    materials: PrincipledMaterial {
        alphaMode: PrincipledMaterial.Blend
        lighting: PrincipledMaterial.NoLighting
        cullMode: Material.NoCulling

        // Use a texture with circular point rendered from a Rectangle
        baseColorMap: Texture {
            minFilter: Texture.Linear
            magFilter: Texture.Linear
            tilingModeHorizontal: Texture.ClampToEdge
            tilingModeVertical: Texture.ClampToEdge

            sourceItem: Rectangle {
                id: circleRect
                width: 64
                height: 64
                radius: 32
                color: "#ff1744"
                antialiasing: true
            }
        }
    }
}
