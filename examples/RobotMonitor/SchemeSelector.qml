pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

ComboBox {
    id: schemeBox

    model: ["Grayscale", "Hot", "Cool", "Jet"]
    font.pixelSize: 16
    font.bold: true

    delegate: ItemDelegate {
        id: paletteDelegate
        required property int index
        required property var model

        width: schemeBox.width - Theme.spacingSmall * 2
        background: Item {}
        contentItem: Text {
            text: schemeBox.model[paletteDelegate.index]

            color: Theme.foreground
            font.pixelSize: 12
            font.bold: schemeBox.currentIndex === paletteDelegate.index
            verticalAlignment: Text.AlignVCenter
        }
    }

    indicator: Item {}

    contentItem: Text {
        leftPadding: Theme.spacingSmall
        rightPadding: Theme.spacingSmall
        text: schemeBox.displayText
        font: schemeBox.font
        color: schemeBox.enabled ? Theme.foreground : Theme.mutedForeground
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitWidth: 140
        implicitHeight: 36
        color: Theme.input
        radius: Theme.radius
        border.color: schemeBox.activeFocus ? Theme.primary : Theme.border
        border.width: schemeBox.activeFocus ? 2 : 1
    }

    popup: Popup {
        id: comboPopup
        y: schemeBox.height - 1
        width: schemeBox.width
        padding: Theme.spacingSmall
        implicitHeight: Math.min(contentItem.implicitHeight + padding * 2, 240)

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: comboPopup.visible ? schemeBox.delegateModel : null
            currentIndex: schemeBox.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator {}
        }

        background: Rectangle {
            color: Theme.card
            radius: Theme.radius
            border.color: Theme.border
        }
    }
}
