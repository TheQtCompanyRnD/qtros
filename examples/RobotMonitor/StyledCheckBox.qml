import QtQuick
import QtQuick.Controls

CheckBox {
    id: layerVisibility

    implicitHeight: indicatorRect.implicitHeight + Theme.spacingSmall * 2
    leftPadding: indicatorRect.implicitWidth + Theme.spacingSmall * 2
    topPadding: Theme.spacingSmall / 2
    bottomPadding: Theme.spacingSmall / 2

    indicator: Rectangle {
        id: indicatorRect
        implicitWidth: 20
        implicitHeight: 20
        radius: 4
        anchors.verticalCenter: parent.verticalCenter
        border.color: layerVisibility.checked ? Theme.primary : Theme.border
        border.width: 2
        color: layerVisibility.checked ? Theme.primary + "33" : "transparent"
        Rectangle {
            anchors.centerIn: parent
            width: 10
            height: 10
            radius: 2
            color: Theme.primary
            visible: layerVisibility.checked
        }
    }
    contentItem: Label {
        text: layerVisibility.text
        color: Theme.foreground
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 16
    }
}
