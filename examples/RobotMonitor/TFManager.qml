// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQml
import QtRos2.GeometryMsgs

// Exposes the per-edge transforms the 3D scene binds to, sourced from a
// FrameTransformer (QtRos2.Transforms) instead of a hand-rolled /tf + /tf_static
// cache. Set `frameTransformer` to the scene's FrameTransformer instance; the
// edge properties are refreshed on its transformsChanged signal.
QtObject {
    id: root

    property var frameTransformer: null

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
    property vector3d rplidar_link_turtlebot4_rplidar_link_rplidar_p: Qt.vector3d(0, 0, 0)
    property quaternion rplidar_link_turtlebot4_rplidar_link_rplidar_q: Qt.quaternion(1, 0, 0, 0)

    // Refresh every edge whenever the TF tree updates.
    property Connections _conn: Connections {
        target: root.frameTransformer
        function onTransformsChanged() { root._refresh() }
    }

    function _refresh() {
        root._setEdge("map", "odom", "map_odom")
        root._setEdge("odom", "base_link", "odom_base_link")
        root._setEdge("base_link", "shell_link", "base_link_shell_link")
        root._setEdge("shell_link", "rplidar_link", "shell_link_rplidar_link")
        root._setEdge("rplidar_link", "turtlebot4/rplidar_link/rplidar",
                      "rplidar_link_turtlebot4_rplidar_link_rplidar")
    }

    // Look up parent->child and push it into the <prefix>_p / <prefix>_q properties.
    function _setEdge(parent: string, child: string, prefix: string) {
        if (!root.frameTransformer || !root.frameTransformer.canTransform(parent, child))
            return
        const tr = root.frameTransformer.lookupTransform(parent, child).transform
        root[prefix + "_p"] = GeometryHeleper.toVector3d(tr.translation)
        root[prefix + "_q"] = GeometryHeleper.toQuaternion(tr.rotation)
    }
}
