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

    // Nodes:
    Node {
        id: scene
        objectName: "Scene"
        rotation: Qt.quaternion(0.707107, -0.707107, 0, 0)
        Model {
            id: link_4
            objectName: "link_4"
            source: "meshes/link_4_001_mesh.mesh"
            materials: [
                black_material
            ]
        }
    }

    // Animations:
}
