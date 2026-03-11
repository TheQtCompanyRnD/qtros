import QtQuick
import QtRos2.Core
import QtRos2.SensorMsgs as SensorMsgs
import QtRos2.Tf2Msgs
import QtRos2.TrajectoryMsgs as TrajectoryMsgs

QtObject {
    id: root
    readonly property list<real> currentPositions: jointStateSubscriber.message.position
    readonly property var jointStates: jointStateSubscriber.message.name.map(
                                           (name, index) => ({
                                                                 "name": name,
                                                                 "position": jointStateSubscriber.message.position[index]
                                                             }))
    readonly property bool moving: jointStateSubscriber.message.velocity.some(vel => vel !== 0.0)

    property bool connected: ros2Node.initialized
    property string controlMode: "ready" // ready, busy, error
    property bool executing: false
    property bool loopEnabled: false

    property var waypoints: []
    property int currentWaypointIndex: -1
    property real executionProgress: 0
    property string executionStatus: "idle"
    property int nextWaypointToSend: 0

    readonly property TFBufferManager tfBuffer: TFBufferManager {
        id: tfBuffer
    }

    readonly property ROS2Node ros2Node: ROS2Node {
        id: ros2Node

        property string jointStateTopic: "/joint_states"
        property string tfTopic: "/tf"
        property string tfStaticTopic: "/tf_static"
        property string trajectoryTopic: "/r6bot_controller/joint_trajectory"
        property string nodeNamePrefix: "qt_r6bot_teach_pendant"

        nodeName: nodeNamePrefix

        readonly property alias jointStateSubscriber: jointStateSubscriber
        readonly property alias tfSubscriber: tfSubscriber
        readonly property alias tfStaticSubscriber: tfStaticSubscriber
        readonly property alias trajectoryPublisher: trajectoryPublisher

        SensorMsgs.JointStateSubscriber {
            id: jointStateSubscriber
            topic: ros2Node.jointStateTopic
        }

        TFMessageSubscriber {
            id: tfSubscriber
            topic: ros2Node.tfTopic
            onMessageReceived: {
                tfBuffer.updateTransforms(tfSubscriber.message)
            }
        }

        TFMessageSubscriber {
            id: tfStaticSubscriber
            topic: ros2Node.tfStaticTopic
            qos.durability: TFMessageSubscriber.DurabilityTransientLocal

            onMessageReceived: {
                tfBuffer.updateTransforms(tfStaticSubscriber.message)
            }
        }

        TrajectoryMsgs.JointTrajectoryPublisher {
            id: trajectoryPublisher
            topic: ros2Node.trajectoryTopic
        }
    }

    // Waypoint completion tracking
    property bool wasMoving: false

    onMovingChanged: {
        if (!executing || nextWaypointToSend >= waypoints.length)
            return

        // Detect when robot stops moving
        if (wasMoving && !moving) {
            currentWaypointIndex = nextWaypointToSend
            nextWaypointToSend++

            // Update progress
            executionProgress = (nextWaypointToSend / waypoints.length) * 100

            // Check if we've sent all waypoints
            if (nextWaypointToSend >= waypoints.length) {
                if (loopEnabled) {
                    // Restart the sequence immediately
                    currentWaypointIndex = -1
                    nextWaypointToSend = 0
                    executionProgress = 0
                    sendNextWaypoint()
                } else {
                    executing = false
                    executionStatus = "completed"
                    executionProgress = 100
                }
            } else {
                // Send next waypoint
                sendNextWaypoint()
            }
        }

        wasMoving = moving
    }

    function sendNextWaypoint() {
        if (nextWaypointToSend >= waypoints.length)
            return

        var waypoint = waypoints[nextWaypointToSend]

        // Calculate duration based on distance
        var distance = 0
        for (var i = 0; i < currentPositions.length; i++) {
            var d = Math.abs(waypoint.positions[i] - currentPositions[i])
            if (d > distance)
                distance = d
        }
        var duration = Math.max(distance / 0.2, 0.5) // 0.2 rad/s, minimum 0.5s

        sendTrajectory([waypoint], duration)
    }

    function captureWaypoint(name, positions) {
        var newWaypoints = waypoints.slice() // Create a copy
        newWaypoints.push({
                              "name": name,
                              "positions": Array.from(positions)
                          })
        waypoints = newWaypoints // Reassign to trigger property change
    }

    function deleteWaypoint(index) {
        var newWaypoints = waypoints.slice() // Create a copy
        newWaypoints.splice(index, 1)
        waypoints = newWaypoints // Reassign to trigger property change
    }

    function jumpToWaypoint(index) {
        if (index < 0 || index >= waypoints.length)
            return

        var waypoint = waypoints[index]
        sendTrajectory([waypoint], 3.0) // 3 second duration
    }

    function jogJoint(jointIndex, delta) {
        if (jointIndex >= currentPositions.length)
            return

        // Create target positions with jog delta applied
        var targetPositions = currentPositions.slice()
        targetPositions[jointIndex] += delta

        var waypoint = {
            "name": "jog",
            "positions": targetPositions
        }
        sendTrajectory([waypoint], 0.5)
    }


    function playSequence() {
        if (waypoints.length < 2)
            return

        executing = true
        executionStatus = "executing"
        currentWaypointIndex = -1
        nextWaypointToSend = 0
        executionProgress = 0
        wasMoving = false

        // Send the first waypoint
        sendNextWaypoint()
    }

    function stopSequence() {
        // Send trajectory with current position and zero velocities to stop smoothly
        trajectoryPublisher.publish({
                                                               "header": {
                                                                   "stamp": {
                                                                       "sec": 0,
                                                                       "nanosec": 0
                                                                   },
                                                                   "frameId": ""
                                                               },
                                                               "jointNames": jointStateSubscriber.message.name,
                                                               "points": [{
                                                                       "positions": currentPositions,
                                                                       "velocities": new Array(currentPositions.length).fill(0),
                                                                       "timeFromStart": {
                                                                           "sec": 0,
                                                                           "nanosec": 0
                                                                       }
                                                                   }]
                                                           })

        executing = false
        executionStatus = "idle"
        currentWaypointIndex = -1
        nextWaypointToSend = 0
        wasMoving = false
    }

    function sendTrajectory(waypointList, durationPerPoint) {
        var numJoints = currentPositions.length
        var points = []
        var timeFromStart = 0.0
        var zeroVelocities =  new Array(currentPositions.length).fill(0)

        // Generate interpolated points for smoother trajectory
        var previousPositions = currentPositions

        for (var i = 0; i < waypointList.length; i++) {
            var waypoint = waypointList[i]

            // Generate 10 intermediate points between previous and current waypoint
            var numIntermediatePoints = 10
            var stepDuration = durationPerPoint / numIntermediatePoints

            for (var step = 0; step <= numIntermediatePoints; step++) {
                var t = step / numIntermediatePoints // 0 to 1
                var positions = []
                var velocities = []

                for (var j = 0; j < numJoints; j++) {
                    // Linear interpolation for position
                    var pos = previousPositions[j] + t * (waypoint.positions[j] - previousPositions[j])
                    positions.push(pos)

                    // Constant velocity during this segment
                    if (step < numIntermediatePoints) {
                        var vel = (waypoint.positions[j] - previousPositions[j]) / durationPerPoint
                        velocities.push(vel)
                    } else {
                        velocities.push(0) // Zero velocity at waypoint
                    }
                }

                points.push({
                    "positions": positions,
                    "velocities": velocities,
                    "timeFromStart": {
                        "sec": Math.floor(timeFromStart),
                        "nanosec": (timeFromStart - Math.floor(timeFromStart)) * 1e9
                    }
                })

                timeFromStart += stepDuration
            }

            previousPositions = waypoint.positions
        }

        // Add final settling point with zero velocities
        timeFromStart += 0.1
        points.push({
            "positions": waypointList[waypointList.length - 1].positions,
            "velocities": zeroVelocities,
            "timeFromStart": {
                "sec": Math.floor(timeFromStart),
                "nanosec": (timeFromStart - Math.floor(timeFromStart)) * 1e9
            }
        })

        // Create trajectory message (using camelCase for QtROS2)
        var trajectory = {
            "header": {
                "stamp": {
                    "sec": 0,
                    "nanosec": 0
                },
                "frameId": ""
            },
            "jointNames": jointStateSubscriber.message.name,
            "points": points
        }

        trajectoryPublisher.publish(trajectory)
    }
}
