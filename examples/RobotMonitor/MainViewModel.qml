import QtQuick
import QtRos2.NavMsgs
import QtRos2.Imported.Tf2Msgs
import QtRos2.SensorMsgs
import QtQuick3D

QtObject {
    id: mainViewModel

    readonly property int totalSubscribers: rosNode.statistics.totalSubscribers
    readonly property int connectedSubscribers: rosNode.statistics.connectedSubscribers
    readonly property int totalPublishers: rosNode.statistics.totalPublishers
    readonly property int connectedPublishers: rosNode.statistics.connectedPublishers
    readonly property int totalActionClients: rosNode.statistics.totalActionClients
    readonly property int connectedActionClients: rosNode.statistics.connectedActionClients

    readonly property var navigationStatus: _actions.item ? _actions.item.navigationStatus : 0
    readonly property var navigationFeedback: _actions.item ? _actions.item.navigationFeedback : null

    readonly property var dockStatus: _actions.item ? _actions.item.dockStatus : 0
    readonly property var dockFeedback: _actions.item ? _actions.item.dockFeedback : null

    readonly property var undockStatus: _actions.item ? _actions.item.undockStatus : 0

    property Loader _actions: Loader {
        source: "Nav2IrobotActions.qml"
        onLoaded: item.node = rosNode
    }

    readonly property alias videoFeed: imageSubscriber.message
    readonly property navmsgs_occupancygrid mapGrid: mapSubscriber.connected ? mapSubscriber.message : ({})
    readonly property MapVisualSettings mapSettings: MapVisualSettings {}

    readonly property navmsgs_occupancygrid localCostmapGrid: localCostmapSubscriber.connected ? localCostmapSubscriber.message : ({})
    readonly property MapVisualSettings localCostmapSettings: MapVisualSettings {
        colorScheme: GridPalette.CostmapHot
        opacity: 0.6
    }

    readonly property navmsgs_occupancygrid globalCostmapGrid: globalCostmapSubscriber.connected ? globalCostmapSubscriber.message : ({})
    readonly property MapVisualSettings globalCostmapSettings: MapVisualSettings {
        colorScheme: GridPalette.CostmapCool
        opacity: 0.4
    }

    readonly property ShapeData plan: ShapeData {
        id: plan
        strokeColor: "purple"
        strokeWidth: 6
    }

    readonly property ShapeData footprint: ShapeData {
        id: footprint
        closed: true
    }

    readonly property GridVisualSettings gridSettings: GridVisualSettings {
        id: gridSettings
    }

    readonly property LaserScanVisualSettings laserScanSettings: LaserScanVisualSettings {
        id: laserScanSettings
    }

    readonly property alias map_odom_p: tfManager.map_odom_p
    readonly property alias map_odom_q: tfManager.map_odom_q

    readonly property alias odom_base_link_p: tfManager.odom_base_link_p
    readonly property alias odom_base_link_q: tfManager.odom_base_link_q

    readonly property alias base_link_shell_link_p: tfManager.base_link_shell_link_p
    readonly property alias base_link_shell_link_q: tfManager.base_link_shell_link_q

    readonly property alias shell_link_rplidar_link_p: tfManager.shell_link_rplidar_link_p
    readonly property alias shell_link_rplidar_link_q: tfManager.shell_link_rplidar_link_q

    readonly property alias rplidar_link_turtlebot4_rplidar_link_rplidar_p: tfManager.rplidar_link_turtlebot4_rplidar_link_rplidar_p
    readonly property alias rplidar_link_turtlebot4_rplidar_link_rplidar_q: tfManager.rplidar_link_turtlebot4_rplidar_link_rplidar_q

    readonly property InstanceList laserScanInstanceList: InstanceList {
        id: laserScanInstanceList
    }

    readonly property QtObject _d: QtObject {
        id: _d

        readonly property TFManager tfManager: TFManager {
            id: tfManager
        }

        readonly property Component instanceListEntryComponent: Component {
            id: laserScanInstanceComponent
            InstanceListEntry {}
        }

        readonly property list<InstanceListEntry> instancePool: []

        readonly property Ros2Node node: Ros2Node {
            id: rosNode
            nodeName: "qt_robot_monitor"

            readonly property var statistics: entities.reduce((acc, ce) => {
                                                                  if (ce instanceof Ros2SubscriberBase) {
                                                                      acc.totalSubscribers++
                                                                      if (ce.connected) {
                                                                          acc.connectedSubscribers++
                                                                      }
                                                                  } else if (ce instanceof Ros2PublisherBase) {
                                                                      acc.totalPublishers++
                                                                      if (ce.subscriberCount > 0) {
                                                                          acc.connectedPublishers++
                                                                      }
                                                                  } else if (ce instanceof Ros2ActionClientBase) {
                                                                      acc.totalActionClients++
                                                                      if (ce.isServerReady) {
                                                                          acc.connectedActionClients++
                                                                      }
                                                                  }
                                                                  return acc
                                                              }, {
                                                                  "totalSubscribers": 0,
                                                                  "connectedSubscribers": 0,
                                                                  "totalPublishers": 0,
                                                                  "connectedPublishers": 0,
                                                                  "totalActionClients": 0,
                                                                  "connectedActionClients": 0
                                                              })

            OccupancyGridSubscriber {
                id: mapSubscriber
                topic: "map"
            }

            OccupancyGridSubscriber {
                id: localCostmapSubscriber
                topic: "local_costmap/costmap"
            }

            OccupancyGridSubscriber {
                id: globalCostmapSubscriber
                topic: "global_costmap/costmap"
            }

            LaserScanSubscriber {
                id: laserScanSubscriber
                topic: "scan"

                onMessageReceived: {
                    _d.updateInstanceList(message)
                }
            }

            TFMessageSubscriber {
                id: tfSubscriber
                topic: "tf"
                onMessageReceived: {
                    tfManager.updateTransforms(message)
                }
            }

            TFMessageSubscriber {
                id: tfStaticSubscriber
                topic: "tf_static"
                qos.durability: TFMessageSubscriber.DurabilityTransientLocal
                onMessageReceived: {
                    tfManager.updateTransforms(message)
                }
            }

            PolygonStampedSubscriber {
                id: footprintSubscriber
                topic: "local_costmap/published_footprint"

                onMessageReceived: {
                    mainViewModel.footprint.sourcePoints = message.polygon.points.map(
                                p => Qt.vector3d(p.x, p.y, p.z))
                }
            }

            PathSubscriber {
                id: pathSubscriber
                topic: "plan"

                onMessageReceived: {
                    mainViewModel.plan.sourcePoints = message.poses.map(
                                poseStamped => Qt.vector3d(
                                    poseStamped.pose.position.x,
                                    poseStamped.pose.position.y,
                                    poseStamped.pose.position.z))
                }
            }

            ImageSubscriber {
                id: imageSubscriber
                topic: "oakd/rgb/preview/image_raw"
            }

            TwistStampedPublisher {
                id: cmdVelPublisher
                topic: "cmd_vel"
            }

            function cancelCurrentAction() {
                if (_actions.item) _actions.item._navigateToPoseAction?.cancelGoal?.()
            }
        }

        function updateInstanceList(laserScan: sensormsgs_laserscan): void {
            let validCount = 0
            const angleMin = laserScan.angleMin
            const angleIncrement = laserScan.angleIncrement
            const rangeMin = laserScan.rangeMin
            const rangeMax = laserScan.rangeMax

            laserScan.ranges.forEach((range, index) => {
                                         if (range < rangeMin
                                             || range > rangeMax) {
                                             return
                                         }

                                         const angle = angleMin + index * angleIncrement
                                         const position = Qt.vector3d(
                                             range * Math.cos(angle),
                                             range * Math.sin(angle), 0)

                                         if (validCount >= _d.instancePool.length) {
                                             _d.instancePool.push(
                                                 laserScanInstanceComponent.createObject(
                                                     mainViewModel.laserScanInstanceList,
                                                     {}))
                                         }
                                         _d.instancePool[validCount].position = position
                                         _d.instancePool[validCount].scale = Qt.vector3d(
                                             1, 1, 1)

                                         validCount++
                                     })

            // Hide unused instances by scaling them to zero
            for (var j = validCount; j < _d.instancePool.length; ++j) {
                _d.instancePool[j].scale = Qt.vector3d(0, 0, 0)
            }

            mainViewModel.laserScanInstanceList.instances = _d.instancePool
        }
    }

    function publishVelocity(vel: geometrymsgs_twist) {
        rosNode.cancelCurrentAction()
        cmdVelPublisher.publish({
                                    "twist": vel
                                })
    }

    function navigateToPose(p: vector3d, yaw: real) {
        rosNode.cancelCurrentAction()
        _actions.item?.navigateToPose(p, yaw)
    }

    function dock() {
        rosNode.cancelCurrentAction()
        _actions.item?.dock()
    }

    function undock() {
        rosNode.cancelCurrentAction()
        _actions.item?.undock()
    }
}
