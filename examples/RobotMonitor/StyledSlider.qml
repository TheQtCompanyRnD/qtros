import QtQuick
import QtQuick.Controls

Slider {
    id: slider

    background: Rectangle {
        x: slider.leftPadding
        y: slider.height / 2 - height / 2
        width: slider.availableWidth
        height: 4
        radius: 2
        color: Theme.secondary
        Rectangle {
            width: parent.width * slider.visualPosition
            height: parent.height
            radius: 2
            color: Theme.primary
        }
    }
    handle: Rectangle {
        implicitWidth: 16
        implicitHeight: 16
        radius: 8
        color: Theme.primary
        border.color: Theme.accent
        x: slider.leftPadding + slider.visualPosition
           * (slider.availableWidth - width)
        y: slider.height / 2 - height / 2
    }
}
