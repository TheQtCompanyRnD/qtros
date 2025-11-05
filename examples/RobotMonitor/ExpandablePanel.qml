import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: expandablePanel

    property alias title: titleLabel.text
    property bool expanded: false
    property bool dragable: false

    default property alias contentItems: content.data

    implicitWidth: content.implicitWidth + 2 * radius
    implicitHeight: 2 * radius + header.height + (expanded ? content.height + 10 : 0)
    clip: true
    radius: Theme.radius
    color: Theme.card
    border.color: Theme.border
    border.width: 1

    MouseArea {
        anchors.fill: parent
    }

    MouseArea {
        anchors.fill: header
        onClicked: {
            expandablePanel.expanded = !expandablePanel.expanded
        }
    }

    RowLayout {
        id: header
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Theme.radius
        height: 32
        spacing: 10

        Label {
            id: titleLabel
            font.pixelSize: 16
            font.bold: true
            color: Theme.foreground
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            color: "transparent"
            radius: 4
            border.color: Theme.accent
            border.width: 2
            visible: expandablePanel.dragable

            Image {
                source: "images/draghandle.svg"
                anchors.centerIn: parent
                width: 20
                height: 20
            }

            MouseArea {
                anchors.fill: parent
                drag.target: expandablePanel
                drag.minimumY: 10
                drag.minimumX: 10
                drag.maximumX: expandablePanel.parent.width - expandablePanel.width - 10
                drag.maximumY: expandablePanel.parent.height - expandablePanel.height - 10
            }
        }

        Rectangle {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            color: "transparent"
            radius: 4
            border.color: Theme.accent
            border.width: 2

            Image {
                source: "images/triangle.svg"
                anchors.centerIn: parent
                width: 15
                height: 15
                transformOrigin: Image.Center
                rotation: expandablePanel.expanded ? 90 : 0
            }
        }
    }

    Column {
        id: content
        anchors.top: header.bottom
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        visible: expandablePanel.expanded
    }
}
