import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: root

    required property var targetRobot
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
    }
}
