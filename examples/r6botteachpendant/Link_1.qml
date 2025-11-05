import QtQuick
import QtQuick3D

Node {
    id: node

    // Resources
    PrincipledMaterial {
        id: orange_material
        objectName: "orange"
        baseColor: "#ffff6a11"
        indexOfRefraction: 1.4500000476837158
    }

    // Nodes:
    Node {
        id: scene
        objectName: "Scene"
        rotation: Qt.quaternion(0.707107, -0.707107, 0, 0)
        Model {
            id: link_1
            objectName: "link_1"
            source: "meshes/link_1_001_mesh.mesh"
            materials: [
                orange_material
            ]
        }
    }

    // Animations:
}
