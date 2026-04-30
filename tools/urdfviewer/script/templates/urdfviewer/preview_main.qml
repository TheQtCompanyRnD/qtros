import QtQuick
import QtQuick.Window

Window {
    width: 1920
    height: 1080
    visible: true
    title: qsTr("{{ base_name }} Preview")

    PreviewScene {
        anchors.fill: parent
    }
}
