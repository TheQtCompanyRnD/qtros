import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs

Item {
    id: root

    required property MainViewModel mainViewModel

    ScrollView {
        id: layersScroll
        anchors.fill: parent
        clip: true

        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            width: layersScroll.width

            ExpandablePanel {
                title: "Grid"
                Layout.fillWidth: true

                Column {
                    width: root.width - 2 * Theme.radius
                    spacing: Theme.spacingSmall

                    StyledCheckBox {
                        text: "Visible"
                        checked: root.mainViewModel.gridSettings.visible
                        onToggled: root.mainViewModel.gridSettings.visible = checked
                    }

                    Label {
                        text: `Opacity: ${gridOpcitySlider.value.toFixed(2)}`
                        color: Theme.mutedForeground
                        font.pixelSize: 12
                    }

                    StyledSlider {
                        id: gridOpcitySlider
                        width: parent.width
                        from: 0
                        to: 1
                        stepSize: 0.05
                        value: root.mainViewModel.gridSettings.opacity
                        onMoved: root.mainViewModel.gridSettings.opacity = value
                    }

                    Label {
                        text: `Cells count: ${gridCellCountSlider.value}`
                        color: Theme.mutedForeground
                        font.pixelSize: 12
                    }

                    StyledSlider {
                        id: gridCellCountSlider
                        width: parent.width
                        from: 5
                        to: 50
                        stepSize: 1
                        value: root.mainViewModel.gridSettings.cellCount
                        onMoved: root.mainViewModel.gridSettings.cellCount = value
                    }

                    Label {
                        text: `Cells size: ${gridWidth.value.toFixed(2)} m`
                        color: Theme.mutedForeground
                        font.pixelSize: 12
                    }

                    StyledSlider {
                        id: gridWidth
                        width: parent.width
                        from: 0.25
                        to: 2
                        stepSize: 0.25
                        value: root.mainViewModel.gridSettings.cellWidth
                        onMoved: root.mainViewModel.gridSettings.cellWidth = value
                    }
                }
            }

            ExpandablePanel {
                title: "Map"
                Layout.fillWidth: true

                Column {
                    width: root.width - 2 * Theme.radius
                    spacing: Theme.spacingSmall

                    StyledCheckBox {
                        text: "Visible"
                        checked: root.mainViewModel.mapSettings.visible
                        onToggled: root.mainViewModel.mapSettings.visible = checked
                    }

                    Label {
                        text: `Opacity: ${mapOpcitySlider.value.toFixed(2)}`
                        color: Theme.mutedForeground
                        font.pixelSize: 12
                    }

                    StyledSlider {
                        id: mapOpcitySlider
                        width: parent.width
                        from: 0
                        to: 1
                        stepSize: 0.05
                        value: root.mainViewModel.mapSettings.opacity
                        onMoved: root.mainViewModel.mapSettings.opacity = value
                    }

                    RowLayout {
                        width: parent.width
                        spacing: Theme.spacingSmall

                        Label {
                            text: "Color scheme"
                            color: Theme.foreground
                            font.pixelSize: 16
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }
                        SchemeSelector {
                            id: schemeSelector
                            Layout.preferredHeight: 24
                            currentIndex: root.mainViewModel.mapSettings.colorScheme
                            onCurrentIndexChanged: root.mainViewModel.mapSettings.colorScheme
                                                   = currentIndex
                        }
                    }
                }
            }

            ExpandablePanel {
                title: "Global costmap"
                Layout.fillWidth: true

                Column {
                    width: root.width - 2 * Theme.radius
                    spacing: Theme.spacingSmall

                    StyledCheckBox {
                        text: "Visible"
                        checked: root.mainViewModel.globalCostmapSettings.visible
                        onToggled: root.mainViewModel.globalCostmapSettings.visible = checked
                    }

                    Label {
                        text: `Opacity: ${globalCostmapOpcitySlider.value.toFixed(
                                  2)}`
                        color: Theme.mutedForeground
                        font.pixelSize: 12
                    }

                    StyledSlider {
                        id: globalCostmapOpcitySlider
                        width: parent.width
                        from: 0
                        to: 1
                        stepSize: 0.05
                        value: root.mainViewModel.globalCostmapSettings.opacity
                        onMoved: root.mainViewModel.globalCostmapSettings.opacity = value
                    }

                    RowLayout {
                        width: parent.width
                        spacing: Theme.spacingSmall

                        Label {
                            text: "Color scheme"
                            color: Theme.foreground
                            font.pixelSize: 16
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }
                        SchemeSelector {

                            Layout.preferredHeight: 24
                            currentIndex: root.mainViewModel.globalCostmapSettings.colorScheme
                            onCurrentIndexChanged: root.mainViewModel.globalCostmapSettings.colorScheme = currentIndex
                        }
                    }
                }
            }

            ExpandablePanel {
                title: "Local costmap"
                Layout.fillWidth: true

                Column {
                    width: root.width - 2 * Theme.radius
                    spacing: Theme.spacingSmall

                    StyledCheckBox {
                        text: "Visible"
                        checked: root.mainViewModel.localCostmapSettings.visible
                        onToggled: root.mainViewModel.localCostmapSettings.visible = checked
                    }

                    Label {
                        text: `Opacity: ${localCostmapOpcitySlider.value.toFixed(
                                  2)}`
                        color: Theme.mutedForeground
                        font.pixelSize: 12
                    }

                    StyledSlider {
                        id: localCostmapOpcitySlider
                        width: parent.width
                        from: 0
                        to: 1
                        stepSize: 0.05
                        value: root.mainViewModel.localCostmapSettings.opacity
                        onMoved: root.mainViewModel.localCostmapSettings.opacity = value
                    }

                    RowLayout {
                        width: parent.width
                        spacing: Theme.spacingSmall

                        Label {
                            text: "Color scheme"
                            color: Theme.foreground
                            font.pixelSize: 16
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }
                        SchemeSelector {

                            Layout.preferredHeight: 24
                            currentIndex: root.mainViewModel.localCostmapSettings.colorScheme
                            onCurrentIndexChanged: root.mainViewModel.localCostmapSettings.colorScheme = currentIndex
                        }
                    }
                }
            }

            ExpandablePanel {
                title: "Laser scan"
                Layout.fillWidth: true

                Column {
                    width: root.width - 2 * Theme.radius
                    spacing: Theme.spacingSmall

                    StyledCheckBox {
                        text: "Visible"
                        checked: root.mainViewModel.laserScanSettings.visible
                        onToggled: root.mainViewModel.laserScanSettings.visible = checked
                    }

                    Label {
                        text: `Opacity: ${laserScanOpcitySlider.value.toFixed(
                                  2)}`
                        color: Theme.mutedForeground
                        font.pixelSize: 12
                    }

                    StyledSlider {
                        id: laserScanOpcitySlider
                        width: parent.width
                        from: 0
                        to: 1
                        stepSize: 0.05
                        value: root.mainViewModel.laserScanSettings.opacity
                        onMoved: root.mainViewModel.laserScanSettings.opacity = value
                    }

                    Label {
                        text: `Point Size: ${laserScanPointSizeSlider.value.toFixed(
                                  2)} m`
                        color: Theme.mutedForeground
                        font.pixelSize: 12
                    }

                    StyledSlider {
                        id: laserScanPointSizeSlider
                        width: parent.width
                        from: 0.01
                        to: 1
                        stepSize: 0.01
                        value: root.mainViewModel.laserScanSettings.pointSize
                        onMoved: root.mainViewModel.laserScanSettings.pointSize = value
                    }

                    ColorSettingsEntry {
                        width: parent.width
                        color: root.mainViewModel.laserScanSettings.color
                        onColorChanged: root.mainViewModel.laserScanSettings.color = color
                    }
                }
            }

            ExpandablePanel {
                title: "Footprint"
                Layout.fillWidth: true

                Column {
                    width: root.width - 2 * Theme.radius
                    spacing: Theme.spacingSmall

                    StyledCheckBox {
                        text: "Visible"
                        checked: root.mainViewModel.footprint.visible
                        onToggled: root.mainViewModel.footprint.visible = checked
                    }

                    Label {
                        text: `Opacity: ${footprintOpcitySlider.value.toFixed(
                                  2)}`
                        color: Theme.mutedForeground
                        font.pixelSize: 12
                    }

                    StyledSlider {
                        id: footprintOpcitySlider
                        width: parent.width
                        from: 0
                        to: 1
                        stepSize: 0.05
                        value: root.mainViewModel.footprint.opacity
                        onMoved: root.mainViewModel.footprint.opacity = value
                    }

                    Label {
                        text: `Stroke width: ${footprintStrokeWidthSlider.value} px`
                        color: Theme.mutedForeground
                        font.pixelSize: 12
                    }

                    StyledSlider {
                        id: footprintStrokeWidthSlider
                        width: parent.width
                        from: 1
                        to: 10
                        stepSize: 1
                        value: root.mainViewModel.footprint.strokeWidth
                        onMoved: root.mainViewModel.footprint.strokeWidth = value
                    }

                    ColorSettingsEntry {
                        width: parent.width
                        color: root.mainViewModel.footprint.strokeColor
                        onColorChanged: root.mainViewModel.footprint.strokeColor = color
                    }
                }
            }

            ExpandablePanel {
                title: "Plan"
                Layout.fillWidth: true

                Column {
                    width: root.width - 2 * Theme.radius
                    spacing: Theme.spacingSmall

                    StyledCheckBox {
                        text: "Visible"
                        checked: root.mainViewModel.plan.visible
                        onToggled: root.mainViewModel.plan.visible = checked
                    }

                    Label {
                        text: `Opacity: ${planOpcitySlider.value.toFixed(2)}`
                        color: Theme.mutedForeground
                        font.pixelSize: 12
                    }

                    StyledSlider {
                        id: planOpcitySlider
                        width: parent.width
                        from: 0
                        to: 1
                        stepSize: 0.05
                        value: root.mainViewModel.plan.opacity
                        onMoved: root.mainViewModel.plan.opacity = value
                    }

                    Label {
                        text: `Stroke width: ${planStrokeWidthSlider.value} px`
                        color: Theme.mutedForeground
                        font.pixelSize: 12
                    }

                    StyledSlider {
                        id: planStrokeWidthSlider
                        width: parent.width
                        from: 1
                        to: 10
                        stepSize: 1
                        value: root.mainViewModel.plan.strokeWidth
                        onMoved: root.mainViewModel.plan.strokeWidth = value
                    }

                    ColorSettingsEntry {
                        width: parent.width
                        color: root.mainViewModel.plan.strokeColor
                        onColorChanged: root.mainViewModel.plan.strokeColor = color
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
