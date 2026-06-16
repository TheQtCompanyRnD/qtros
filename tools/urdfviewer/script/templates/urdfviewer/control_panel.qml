import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: root

    required property var targetRobot
    property var physicsWorld: null
    property var joints: targetRobot && targetRobot.control ? targetRobot.control.jointInfos : []
    clip: true

    Connections {
        target: root.targetRobot && root.targetRobot.control ? root.targetRobot.control : null
        ignoreUnknownSignals: true
        function onJointInfosChanged() {
            root.joints = root.targetRobot && root.targetRobot.control ? root.targetRobot.control.jointInfos : [];
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 6

        Repeater {
            model: root.joints
            delegate: Pane {
                Layout.fillWidth: true
                padding: 8

                required property string name
                required property real lower
                required property real upper
                required property string type

                RowLayout {
                    anchors.fill: parent

                    Text { text: name; width: 40 }
                    Slider {
                        id: s; from: lower; to: upper; Layout.fillWidth: true
                        stepSize: type === "prismatic" ? 0.001 : 0.1

                        onValueChanged: {
                            root.targetRobot.control[name] = value;
                        }
                    }
                    Text { text: Number(s.value).toFixed(1); width: 50; horizontalAlignment: Text.AlignRight }
                }
            }
        }

        Pane {
            Layout.fillWidth: true
            padding: 8
            visible: root.physicsWorld !== null

            ColumnLayout {
                anchors.fill: parent
                spacing: 4

                Label {
                    text: qsTr("Physics")
                    font.bold: true
                }

                RowLayout {
                    Layout.fillWidth: true

                    Label { text: qsTr("Running"); Layout.fillWidth: true }
                    Switch {
                        checked: root.physicsWorld ? root.physicsWorld.running : false
                        onToggled: root.physicsWorld.running = checked
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Label { text: qsTr("Debug Draw"); Layout.fillWidth: true }
                    Switch {
                        checked: root.physicsWorld ? root.physicsWorld.forceDebugDraw : false
                        onToggled: root.physicsWorld.forceDebugDraw = checked
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Label { text: qsTr("Kinematic"); Layout.fillWidth: true }
                    Switch {
                        checked: root.targetRobot && root.targetRobot.control ? root.targetRobot.control.isKinematic : true
                        onToggled: root.targetRobot.control.isKinematic = checked
                    }
                }
            }
        }
    }
}
