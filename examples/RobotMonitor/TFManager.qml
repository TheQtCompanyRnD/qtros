// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQml
import QtRos2.Imported.Tf2Msgs
import QtRos2.GeometryMsgs

// TFBufferManager is a specialized component that caches the local transforms
// for the TurtleBot4 navigation stack as explicit, typed properties.
// Only the transforms needed for navigation visualization are cached.
QtObject {
    id: root

    // List of transforms we care about (parent_child format)
    readonly property list<string> observedTransforms: ["map_odom", "odom_base_link", "base_link_shell_link", "shell_link_rplidar_link", "rplidar_link_turtlebot4_rplidar_link_rplidar"]

    // --- Public, Bindable Transform Properties ---
    property var cachedTransforms: new Map()

    // map -> odom
    property vector3d map_odom_p: Qt.vector3d(0, 0, 0)
    property quaternion map_odom_q: Qt.quaternion(1, 0, 0, 0)

    // odom -> base_link
    property vector3d odom_base_link_p: Qt.vector3d(0, 0, 0)
    property quaternion odom_base_link_q: Qt.quaternion(1, 0, 0, 0)

    // base_link -> shell_link
    property vector3d base_link_shell_link_p: Qt.vector3d(0, 0, 0)
    property quaternion base_link_shell_link_q: Qt.quaternion(1, 0, 0, 0)

    // shell_link -> rplidar_link
    property vector3d shell_link_rplidar_link_p: Qt.vector3d(0, 0, 0)
    property quaternion shell_link_rplidar_link_q: Qt.quaternion(1, 0, 0, 0)

    // rplidar_link -> turtlebot4/rplidar_link/rplidar
    property vector3d rplidar_link_turtlebot4_rplidar_link_rplidar_p: Qt.vector3d(
                                                                          0, 0,
                                                                          0)
    property quaternion rplidar_link_turtlebot4_rplidar_link_rplidar_q: Qt.quaternion(
                                                                            1,
                                                                            0,
                                                                            0,
                                                                            0)

    function normalizeName(name: string): string {
        name.replace("/", "_")

        return !name.startsWith("_") ? name : name.substr(1)
    }

    // Called by the ROS2 subscriber with incoming TF messages.
    function updateTransforms(tfMessage: qtros2tf2msgs_tfmessage) {
        if (!tfMessage || !tfMessage.transforms)
            return

        let dirtyTransforms = []

        // Qt 6.10 handles that properly - although qmlls still reports the warning
        tfMessage.transforms.forEach(
                    function (tfm/*: qtros2geometrymsgs_transformstamped*/ ) {
                        const frameId = normalizeName(tfm.header.frameId)
                        const childId = normalizeName(tfm.childFrameId)
                        const key = frameId + "_" + childId

                        // Skip transforms we don't care about
                        if (!observedTransforms.includes(key)) {
                            return
                        }

                        let val = cachedTransforms[key]
                        if (!!!val || val.transform !== tfm.transform) {
                            cachedTransforms[key] = tfm
                            dirtyTransforms.push(tfm)
                        }
                    })

        dirtyTransforms.forEach(
                    // Qt 6.10 handles that properly - although qmlls still reports the warning
                    function (tfm/*: qtros2geometrymsgs_transformstamped*/ ) {
                        const frameId = normalizeName(tfm.header.frameId)
                        const childId = normalizeName(tfm.childFrameId)

                        const base_prop_name = frameId + "_" + childId

                        root[base_prop_name + "_p"] = GeometryHeleper.toVector3d(
                                    tfm.transform.translation)
                        root[base_prop_name + "_q"] = GeometryHeleper.toQuaternion(
                                    tfm.transform.rotation)
                    })
    }
}
