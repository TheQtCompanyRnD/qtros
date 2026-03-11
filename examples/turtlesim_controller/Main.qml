pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QtRos2.Core
import QtRos2.Imported.Turtlesim

ApplicationWindow {
    id: root
    visible: true
    width: 800
    height: 1000
    title: "TurtleSim Controller"

    property list<string> turrtles: []
    property list<TurtleControllerNode> viewModels: []

    property TurtleControllerNode currentViewModel: viewModels[turtleSelection.currentIndex]
    ?? null
    property int currentIndex: turtleSelection.currentIndex

    ROS2Node {
        id: rootRosNode
        nodeName: `qt_main_node`

        SpawnServiceClient {
            id: spawnService
            topic: "/spawn"

            onIsServiceReadyChanged: {
                if (spawnService.isServiceReady) {
                    Qt.callLater(() => root.addTurtle("turtle1"))
                }
            }
        }

        KillServiceClient {
            id: killService
            topic: "/kill"
        }
    }

    Component {
        id: turtleViewModel

        TurtleControllerNode {}
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        RowLayout {

            spacing: 12

            ComboBox {
                id: turtleSelection
                model: root.turrtles
            }

            Button {
                id: killButton
                text: "Kill"
                onClicked: {
                    if (turtleSelection.currentIndex !== -1) {
                        const turtleName = turtleSelection.currentText
                        killService.callService(turtleName).then(() => {
                                                                     let index = turtleSelection.currentIndex
                                                                     viewModels[index].destroy()
                                                                     viewModels.splice(
                                                                         index,
                                                                         1)
                                                                     turrtles.splice(
                                                                         index,
                                                                         1)
                                                                 })
                    }
                }
            }

            Button {
                id: drawQtButton
                text: "Draw Qt"
                enabled: root.currentViewModel !== null
                onClicked: root.currentViewModel?.drawQt(redSlider.value,
                                                         greenSlider.value,
                                                         blueSlider.value,
                                                         widthSlider.value)
            }
        }

        RowLayout {

            spacing: 12

            Label {
                text: "Name:"
                font.pixelSize: 13
                font.bold: true
            }

            TextField {
                id: nameEdit
            }

            Label {
                text: "X:"
                font.pixelSize: 13
                font.bold: true
            }

            SpinBox {
                id: x
                from: -1
                to: 11
                stepSize: 1
                editable: true
            }

            Label {
                text: "y:"
                font.pixelSize: 13
                font.bold: true
            }

            SpinBox {
                id: y
                from: -1
                to: 11
                stepSize: 1
                editable: true
            }

            Button {
                id: spawn
                enabled: !spawnService.isCallPending

                text: "Spawn"

                onClicked: {
                    spawnService.callService({
                                                 "name": nameEdit.text,
                                                 "x": x.value,
                                                 "y": y.value
                                             }).then(name => {
                                                         if (!name) {
                                                             throw new Error("Failed to spawn: name taken or invalid position")
                                                         }

                                                         root.addTurtle(name)
                                                     }).catch(
                        error => console.log("Failed to spawn", error))
                }
            }
        }

        Rectangle {
            Layout.preferredHeight: 3
            color: "black"
            Layout.fillWidth: true
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                visible: !!root.currentViewModel
                anchors.fill: parent
                anchors.margins: 5

                spacing: 12

                GroupBox {
                    title: "Current Turtle Pose"
                    Layout.fillWidth: true

                    ColumnLayout {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top

                        spacing: 8
                        GridLayout {
                            columns: 4
                            columnSpacing: 12
                            rowSpacing: 5
                            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter

                            Label {
                                id: xLabel
                                text: "X: " + root.currentViewModel?.pose.x.toFixed(
                                          3)
                                font.pixelSize: 13
                            }
                            Label {
                                id: yLabel
                                text: "Y: " + root.currentViewModel?.pose.y.toFixed(
                                          3)
                                font.pixelSize: 13
                            }
                            Label {
                                id: thetaLabel
                                text: `θ: ${root.currentViewModel?.pose.theta.toFixed(
                                          3)} rad (${(root.currentViewModel?.pose.theta
                                                      * 180 / Math.PI).toFixed(
                                          1)}°)`
                                font.pixelSize: 13
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    GroupBox {
                        title: "Move"
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ColumnLayout {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top

                            spacing: 8

                            GridLayout {
                                columns: 3
                                rowSpacing: 4
                                columnSpacing: 4
                                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter

                                Item {
                                    Layout.preferredWidth: 70
                                    Layout.preferredHeight: 60
                                }

                                Button {
                                    text: "▲"
                                    autoRepeat: true
                                    Layout.preferredWidth: 70
                                    Layout.preferredHeight: 60
                                    onPressed: root.currentViewModel.publishVelocity(
                                                   2.0, 0, 0, 0, 0, 0)
                                }
                                Item {
                                    Layout.preferredWidth: 70
                                    Layout.preferredHeight: 60
                                }

                                Button {
                                    text: "◄"
                                    Layout.preferredWidth: 70
                                    Layout.preferredHeight: 60
                                    onPressed: root.currentViewModel.publishVelocity(
                                                   0, 0, 0, 0, 0, 2.0)
                                }
                                Button {
                                    text: "⬤"
                                    Layout.preferredWidth: 70
                                    Layout.preferredHeight: 60
                                    onClicked: root.currentViewModel.publishVelocity(
                                                   0, 0, 0, 0, 0, 0)
                                }
                                Button {
                                    text: "►"
                                    Layout.preferredWidth: 70
                                    Layout.preferredHeight: 60
                                    onPressed: root.currentViewModel.publishVelocity(
                                                   0, 0, 0, 0, 0, -2.0)
                                }

                                Item {
                                    Layout.preferredWidth: 70
                                    Layout.preferredHeight: 60
                                }
                                Button {
                                    text: "▼"
                                    Layout.preferredWidth: 70
                                    Layout.preferredHeight: 60
                                    onPressed: root.currentViewModel.publishVelocity(
                                                   -2.0, 0, 0, 0, 0, 0)
                                }
                                Item {
                                    Layout.preferredWidth: 70
                                    Layout.preferredHeight: 60
                                }
                            }

                            GroupBox {
                                title: "Move Absolute"
                                Layout.fillWidth: true

                                ColumnLayout {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 4

                                    RowLayout {
                                        spacing: 4

                                        Label {

                                            text: "X"
                                            font.pixelSize: 11
                                        }

                                        SpinBox {
                                            id: teleportX
                                            from: 0
                                            to: 11
                                            stepSize: 1
                                            editable: true
                                        }

                                        Label {

                                            text: "Y"
                                            font.pixelSize: 11
                                        }

                                        SpinBox {
                                            id: teleportY
                                            from: 0
                                            to: 11
                                            stepSize: 1
                                            editable: true
                                        }

                                        Label {

                                            text: "Angle"
                                            font.pixelSize: 11
                                        }

                                        SpinBox {
                                            id: teleportAngle
                                            from: 0
                                            to: 360
                                            stepSize: 1
                                            editable: true
                                        }
                                    }
                                    Button {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "Move"
                                        onClicked: root.currentViewModel.teleportAbsoluteService.callService({
                                                                                                                 "x": teleportX.value,
                                                                                                                 "y": teleportY.value,
                                                                                                                 "theta": teleportAngle.value * Math.PI / 180
                                                                                                             })
                                    }
                                }
                            }

                            GroupBox {
                                title: "Move Relative"
                                Layout.fillWidth: true

                                ColumnLayout {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 4
                                    RowLayout {
                                        spacing: 4

                                        Label {

                                            text: "Linear"
                                            font.pixelSize: 11
                                        }

                                        SpinBox {
                                            id: teleportLinear
                                            from: 0
                                            to: 11
                                            stepSize: 1
                                            editable: true
                                        }

                                        Label {

                                            text: "Angle"
                                            font.pixelSize: 11
                                        }

                                        SpinBox {
                                            id: teleportAngular
                                            from: 0
                                            to: 360
                                            stepSize: 1
                                            editable: true
                                        }
                                    }
                                    Button {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "Move"
                                        onClicked: root.currentViewModel.teleportRelativeService.callService({
                                                                                                                 "angular": teleportAngular.value * Math.PI / 180,
                                                                                                                 "linear": teleportLinear.value
                                                                                                             }).then(
                                                       () => console.log(
                                                           "Move (relative) succeed!")).catch(
                                                       e => {
                                                           console.log(
                                                               `Move (relative) failed! ${e}`)
                                                       })
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }
                        }
                    }

                    GroupBox {
                        title: "Absolute heading"
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ColumnLayout {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top

                            spacing: 8

                            GridLayout {
                                columns: 3
                                rowSpacing: 4
                                columnSpacing: 4
                                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter

                                Item {
                                    Layout.preferredWidth: 70
                                    Layout.preferredHeight: 60
                                }
                                Button {
                                    text: "90° ▲"
                                    Layout.preferredWidth: 70
                                    Layout.preferredHeight: 60
                                    onClicked: root.currentViewModel.sendRotationGoal(
                                                   Math.PI / 2)
                                }
                                Item {
                                    Layout.preferredWidth: 70
                                    Layout.preferredHeight: 60
                                }

                                Button {
                                    text: "180° ◄"
                                    Layout.preferredWidth: 70
                                    Layout.preferredHeight: 60
                                    onClicked: root.currentViewModel.sendRotationGoal(
                                                   Math.PI)
                                }
                                Item {
                                    Layout.preferredWidth: 70
                                    Layout.preferredHeight: 60
                                }
                                Button {
                                    text: "0° ►"
                                    Layout.preferredWidth: 70
                                    Layout.preferredHeight: 60
                                    onClicked: root.currentViewModel.sendRotationGoal(
                                                   0.0)
                                }

                                Item {
                                    Layout.preferredWidth: 70
                                    Layout.preferredHeight: 60
                                }
                                Button {
                                    text: "-90° ▼"
                                    Layout.preferredWidth: 70
                                    Layout.preferredHeight: 60
                                    onClicked: root.currentViewModel.sendRotationGoal(
                                                   -Math.PI / 2)
                                }
                                Item {
                                    Layout.preferredWidth: 70
                                    Layout.preferredHeight: 60
                                }
                            }

                            RowLayout {
                                spacing: 4

                                Label {

                                    text: "Angle"
                                    font.pixelSize: 11
                                }

                                SpinBox {
                                    id: angle
                                    from: 0
                                    to: 360
                                    stepSize: 1
                                    editable: true
                                }

                                Button {
                                    text: "Set Angle"
                                    onClicked: root.currentViewModel.sendRotationGoal(
                                                   angle.value * Math.PI / 180)
                                }
                            }

                            Label {
                                id: actionStatusLabel
                                text: root?.currentViewModel?.rotateStatusText
                                      ?? "Status: N/A"
                                font.pixelSize: 12
                            }
                            Label {
                                id: feedbackLabel
                                text: root?.currentViewModel?.rotateFeedbackText
                                      ?? "Feedback: N/A"
                                font.pixelSize: 11
                            }
                            Label {
                                id: resultLabel
                                text: root?.currentViewModel?.rotateResultText
                                      ?? "Result: N/A"
                                font.pixelSize: 11
                            }

                            Button {
                                text: "Cancel Rotation"

                                enabled: (root.currentViewModel?.rotateAction.state
                                          ?? -1) === RotateAbsoluteActionClient.Accepted
                                onClicked: root.currentViewModel.rotateAction.cancelGoal()
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }
                        }
                    }
                }

                GroupBox {
                    title: "Pen Settings"
                    Layout.alignment: Qt.AlignTop
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8

                        // Preset colors
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            Repeater {
                                model: ["red", "green", "blue", "yellow", "purple", "orange", "black", "white"]

                                ItemDelegate {
                                    id: colorButton
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 20
                                    required property color modelData
                                    contentItem: Item {}
                                    background: Rectangle {
                                        id: colorRect
                                        border.color: "black"
                                        border.width: 2
                                        radius: 4
                                        color: colorButton.modelData
                                    }

                                    onClicked: root.setPenColor(
                                                   colorButton.modelData.r * 255,
                                                   colorButton.modelData.g * 255,
                                                   colorButton.modelData.b * 255)
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: "#dddddd"
                        }

                        // Custom RGB sliders
                        Label {
                            text: "Custom Color:"
                            font.bold: true
                        }

                        GridLayout {
                            columns: 3
                            columnSpacing: 8
                            rowSpacing: 5

                            Label {
                                text: "R:"
                            }
                            Slider {
                                id: redSlider
                                from: 0
                                to: 255
                                value: 255
                                stepSize: 1
                                Layout.fillWidth: true
                            }
                            Label {
                                text: redSlider.value.toFixed(0)
                                Layout.preferredWidth: 40
                            }

                            Label {
                                text: "G:"
                            }
                            Slider {
                                id: greenSlider
                                from: 0
                                to: 255
                                value: 255
                                stepSize: 1
                                Layout.fillWidth: true
                            }
                            Label {
                                text: greenSlider.value.toFixed(0)
                                Layout.preferredWidth: 40
                            }

                            Label {
                                text: "B:"
                            }
                            Slider {
                                id: blueSlider
                                from: 0
                                to: 255
                                value: 255
                                stepSize: 1
                                Layout.fillWidth: true
                            }
                            Label {
                                text: blueSlider.value.toFixed(0)
                                Layout.preferredWidth: 40
                            }
                        }

                        // Color preview
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            color: Qt.rgba(redSlider.value / 255,
                                           greenSlider.value / 255,
                                           blueSlider.value / 255, 1.0)
                            border.color: "black"
                            border.width: 2
                            radius: 4
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: "#dddddd"
                        }

                        // Pen width
                        RowLayout {
                            Label {
                                text: "Pen Width:"
                            }
                            Slider {
                                id: widthSlider
                                from: 1
                                to: 20
                                value: 3
                                stepSize: 1
                                Layout.fillWidth: true
                            }
                            Label {
                                text: widthSlider.value.toFixed(0)
                            }
                        }

                        // Pen on/off
                        CheckBox {
                            id: penOffCheckbox
                            text: "Pen Off (don't draw trail)"
                        }

                        Button {
                            text: "Apply Custom Color"
                            Layout.fillWidth: true

                            onClicked: {
                                root.currentViewModel.setPenService.callService(
                                    {
                                        "r": redSlider.value,
                                        "g": greenSlider.value,
                                        "b": blueSlider.value,
                                        "width": widthSlider.value,
                                        "off": penOffCheckbox.checked
                                    }).then(() => {
                                                console.log("SetPen succeed!")
                                            }).catch(e => {
                                                         console.log(
                                                             `SetPen failed! ${e}`)
                                                     })
                            }
                        }
                    }
                }
            }
        }
    }

    function addTurtle(name: string): void {
        if (!root.turrtles.includes(name)) {

            root.turrtles.push(name)
            viewModels.push(turtleViewModel.createObject(root, {
                                                             "rosNode": rootRosNode,
                                                             "baseName": name
                                                         }))

            turtleSelection.currentIndex = turrtles.indexOf(name)
        }
    }

    function setPenColor(r, g, b) {
        redSlider.value = r
        greenSlider.value = g
        blueSlider.value = b
    }
}
