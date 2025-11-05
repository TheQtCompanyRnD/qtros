import QtQuick

Item {
    id: root

    required property MainViewModel mainViewModel

    Grid {
        id: dpad
        anchors.top: parent.top
        anchors.topMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        columns: 3
        rowSpacing: Theme.spacingSmall
        columnSpacing: Theme.spacingSmall

        Item {
            width: 100
            height: 80
        }

        StyledButton {
            text: "▲"
            width: 100
            height: 80
            autoRepeat: true
            onPressed: root.mainViewModel.publishVelocity({
                                                              "linear": {
                                                                  "x": 0.5
                                                              }
                                                          })
        }

        Item {
            width: 100
            height: 80
        }

        StyledButton {
            text: "◄"
            width: 100
            height: 80
            font.pixelSize: 24
            autoRepeat: true
            onPressed: root.mainViewModel.publishVelocity({
                                                              "angular": {
                                                                  "z": 0.5
                                                              }
                                                          })
        }

        StyledButton {
            text: "⬤"
            width: 100
            height: 80
            font.pixelSize: 20
            onClicked: root.mainViewModel.publishVelocity({})
        }

        StyledButton {
            text: "►"
            width: 100
            height: 80
            font.pixelSize: 24
            autoRepeat: true
            onPressed: root.mainViewModel.publishVelocity({
                                                              "angular": {
                                                                  "z": -0.5
                                                              }
                                                          })
        }

        Item {
            width: 100
            height: 80
        }

        StyledButton {
            text: "▼"
            width: 100
            height: 80
            font.pixelSize: 24
            autoRepeat: true
            onPressed: root.mainViewModel.publishVelocity({
                                                              "linear": {
                                                                  "x": -0.5
                                                              }
                                                          })
        }

        Item {
            width: 100
            height: 80
        }

        StyledButton {
            text: "Undock"
            width: 100
            height: 40

            onClicked: root.mainViewModel.undock()
        }

        Item {
            width: 100
            height: 80
        }

        StyledButton {
            text: "Dock"
            width: 100
            height: 40

            onClicked: root.mainViewModel.dock()
        }
    }
}
