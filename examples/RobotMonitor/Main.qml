import QtQuick
import QtQuick.Layouts

Window {
    id: window
    width: 640
    height: 480
    visible: true
    color: Theme.background
    title: qsTr("Robot Monitor")

    readonly property MainViewModel mainViewModel: MainViewModel {}

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        StatusRow {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.headerHeight
            mainViewModel: window.mainViewModel
        }

        RowLayout {

            spacing: 10

            SceneView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                mainViewModel: window.mainViewModel

                ExpandablePanel {
                    x: 20
                    y: 20
                    dragable: true
                    title: "Camera Feed"
                    VideoView {
                        image: window.mainViewModel.videoFeed
                    }
                }
            }

            SidePanel {
                Layout.preferredWidth: Theme.sidePanelWidth
                Layout.fillHeight: true
                mainViewModel: window.mainViewModel
            }
        }
    }
}
