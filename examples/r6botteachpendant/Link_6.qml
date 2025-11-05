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
            id: link_6
            objectName: "link_6"
            source: "meshes/link_6_001_mesh.mesh"
            materials: [
                grey_material
            ]
        }
    }

    // Animations:
}
