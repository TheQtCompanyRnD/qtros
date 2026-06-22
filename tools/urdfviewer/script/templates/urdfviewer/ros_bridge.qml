import QtQuick
import QtRos2.Core as Ros2
import QtRos2.SensorMsgs as SensorMsgs

// Subscribes to a ROS 2 /joint_states topic and drives a {{ base_name }}Control object.
// Embed this component alongside your 3D scene; it has no visual appearance.
//
// Usage:
//   {{ base_name }}Control { id: ctrl }
//   RosBridge { control: ctrl }
QtObject {
    id: root

    // The control object whose joint properties will be driven from ROS.
    required property var control

    // Disabling/enabling processing of the messages.
    property bool processMessages: true

    // Topic to subscribe to. Override for namespaced robots, e.g.:
    //   jointStateTopic: "/my_robot/joint_states"
    property string jointStateTopic: "{{ joint_states_topic }}"

    // Maps ROS joint names to QML property names on {{ base_name }}Control.
    // Generated from URDF at export time; update when joint names change.
    readonly property var _jointRosNameMap: ({
{% for entry in joint_map %}
        "{{ entry.ros_name }}": "{{ entry.qml_prop }}",
{% endfor %}
    })

    property var _ros2Node: Ros2.Node {
        nodeName: "urdf_bridge_node"

        SensorMsgs.JointStateSubscriber {
            topic: root.jointStateTopic
            onMessageReceived: (msg) => {
	        if (root.processMessages) {
                    const names = msg.name
                    const positions = msg.position
                    for (let i = 0; i < names.length; ++i) {
                        const prop = root._jointRosNameMap[names[i]]
                        if (prop !== undefined)
                            root.control[prop] = positions[i]
                    }
		}
            }
        }
    }

    // True once the underlying Node has fully initialised.
    readonly property bool initialized: _ros2Node.initialized
}
