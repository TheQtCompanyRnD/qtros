import QtQuick
import QtQuick3D
import QtQuick3D.Helpers
import QtROS2.NavMsgs

Node {
    id: gridNode
    property qtros2navmsgs_occupancygrid grid: ({})
    property bool applyOriginTransform: true // Set to false when parent handles transform

    property alias scheme: gridPalette.scheme

    readonly property real resolution: grid.info.resolution
    readonly property real width: grid.info.width
    readonly property real height: grid.info.height
    readonly property real realWidth: width * resolution
    readonly property real realHeight: height * resolution

    position: GeometryHeleper.toVector3d(grid.info.origin.position)

    rotation: GeometryHeleper.toQuaternion(grid.info.origin.orientation)

    Model {
        position: Qt.vector3d(gridNode.realWidth / 2,
                              gridNode.realHeight / 2, 0)

        // In Qt 6.9+ we could use:
        // PlaneGeometry {
        //     id: planeGeometry
        //     width: gridNode.realWidth
        //     height: gridNode.realHeight

        //     plane: PlaneGeometry.XY
        //     mirrored: true
        // }
        geometry: ProceduralMesh {
            property real w2: gridNode.realWidth / 2
            property real h2: gridNode.realHeight / 2

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

        materials: CustomMaterial {
            shadingMode: CustomMaterial.Unshaded
            cullMode: Material.NoCulling
            sourceBlend: CustomMaterial.SrcAlpha
            destinationBlend: CustomMaterial.OneMinusSrcAlpha

            // 1. Raw Data Input
            property TextureInput indexMap: TextureInput {
                texture: Texture {
                    minFilter: Texture.Nearest // Vital for crisp pixels
                    magFilter: Texture.Nearest
                    tilingModeHorizontal: Texture.ClampToEdge
                    tilingModeVertical: Texture.ClampToEdge

                    textureData: ProceduralTextureData {
                        textureData: gridNode.grid.data
                        width: gridNode.grid.info.width
                        height: gridNode.grid.info.height
                        format: ProceduralTextureData.R8
                    }
                }
            }

            // 2. Palette Input (Shared)
            property TextureInput paletteMap: TextureInput {
                texture: Texture {
                    textureData: GridPalette {
                        id: gridPalette
                    }
                    minFilter: Texture.Nearest
                    magFilter: Texture.Nearest
                    tilingModeHorizontal: Texture.ClampToEdge
                    tilingModeVertical: Texture.ClampToEdge
                }
            }

            property real opacity: gridNode.opacity

            fragmentShader: "shaders/IndexedGrid.frag"
            vertexShader: "shaders/IndexedGrid.vert"
        }
    }
}
