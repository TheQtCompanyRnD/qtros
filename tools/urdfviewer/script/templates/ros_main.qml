import QtQuick
import QtQuick.Window
import QtRos2.Core

Window {
    width: 1920
    height: 1080
    visible: true
    title: qsTr("{{ base_name }} ROS Preview")

    // Initialises the ROS 2 context before any ROS2Node is created.
    // Add nodeArgs here for remapping or other --ros-args options, e.g.:
    //   nodeArgs: ["--ros-args", "--remap", "/joint_states:=/robot/joint_states"]
    Ros2Context {}

    RosPreviewScene {
        anchors.fill: parent
    }
}
