import QtQuick
import QtQuick3D
import QtQuick3D.Helpers

Model {
    id: gridModel

    property int resolution: 20
    property real gridStep: 1

    geometry: GridGeometry {
        horizontalLines: gridModel.resolution + 1
        horizontalStep: gridModel.gridStep
        verticalLines: gridModel.resolution + 1
        verticalStep: gridModel.gridStep
    }
    materials: DefaultMaterial {
        // 1. Set the color here
        diffuseColor: "darkgray"

        // 2. Crucial: Lines don't react well to scene lights,
        // so use NoLighting to see the raw color.
        lighting: DefaultMaterial.NoLighting

        // 3. Optional: Control line thickness (Note: hardware dependent)
        lineWidth: 1.0
    }
}
