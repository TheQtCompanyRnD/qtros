pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property var joints: []

    height: Theme.headerHeight
    color: Theme.card

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.border
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingMedium
        anchors.rightMargin: Theme.spacingMedium
        spacing: Theme.spacingLarge



        Item { Layout.fillWidth: true }

        // Joint Snapshot
        RowLayout {
            spacing: Theme.spacingMedium

            Label {
                text: "JOINTS"
                color: Theme.mutedForeground
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 1
            }

            Repeater {
                model: Math.min(6, root.joints.length)
                delegate: RowLayout {
                    id: jointValue
                    required property int index

                    spacing: 4
                    Label {
                        text: root.joints[jointValue.index].name + ":"
                        color: Theme.mutedForeground
                        font.pixelSize: 11
                    }
                    Label {
                        text: root.joints[jointValue.index].position.toFixed(2)
                        color: Theme.foreground
                        font.family: Theme.monoFontFamily
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
