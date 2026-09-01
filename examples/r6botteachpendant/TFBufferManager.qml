// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQml

// Exposes the r6bot kinematic-chain transforms the 3D model binds to, sourced
// from a FrameTransformer (QtRos2.Transforms) instead of a hand-rolled /tf cache.
// Set `frameTransformer`; the edge properties refresh on its transformsChanged.
// The property defaults are the URDF rest pose, shown until /tf arrives.
QtObject {
    id: root

    property var frameTransformer: null

    // True once every edge in the chain is resolvable from the TF tree.
    property bool transformsReady: false

    // ft_frame -> tool0
    property vector3d ft_frame_tool0_p: Qt.vector3d(0.0, 0.0, 0.185)
    property quaternion ft_frame_tool0_q: Qt.quaternion(1, 0, 0, 0)

    // link_6 -> ft_frame
    property vector3d link_6_ft_frame_p: Qt.vector3d(0.0, 0.0, 0.0)
    property quaternion link_6_ft_frame_q: Qt.quaternion(1, 0, 0, 0)

    // link_5 -> link_6
    property vector3d link_5_link_6_p: Qt.vector3d(-0.085976, 0.0, 0.133436)
    property quaternion link_5_link_6_q: Qt.quaternion(0.7071067811865476, 0.0, -0.7071067811865475, 0.0)

    // link_4 -> link_5
    property vector3d link_4_link_5_p: Qt.vector3d(0.112654, 0.0, 0.110903)
    property quaternion link_4_link_5_q: Qt.quaternion(0.49999999999999994, -0.49999999999999994, 0.5000000000000001, -0.49999999999999994)

    // link_3 -> link_4
    property vector3d link_3_link_4_p: Qt.vector3d(0.518777, 0.0, 0.067458)
    property quaternion link_3_link_4_q: Qt.quaternion(-1.5848095757158815e-17, -0.9659258262890683, -0.25881904510252063, 5.914589856893349e-17)

    // link_2 -> link_3
    property vector3d link_2_link_3_p: Qt.vector3d(0.685682, 0.0, 0.041861)
    property quaternion link_2_link_3_q: Qt.quaternion(-4.329780281177466e-17, -0.7071067811865476, -0.7071067811865475, 4.329780281177467e-17)

    // link_1 -> link_2
    property vector3d link_1_link_2_p: Qt.vector3d(-0.101717, 0.0, 0.182284)
    property quaternion link_1_link_2_q: Qt.quaternion(0.6830127018922193, -0.18301270189221935, -0.6830127018922192, 0.18301270189221935)

    // base_link -> link_1
    property vector3d base_link_link_1_p: Qt.vector3d(0.0, 0.0, 0.061584)
    property quaternion base_link_link_1_q: Qt.quaternion(1, 0, 0, 0)

    // world -> base_link
    property vector3d world_base_link_p: Qt.vector3d(0.0, 0.0, 0.0)
    property quaternion world_base_link_q: Qt.quaternion(1, 0, 0, 0)

    readonly property var _edges: [
        ["ft_frame", "tool0", "ft_frame_tool0"],
        ["link_6", "ft_frame", "link_6_ft_frame"],
        ["link_5", "link_6", "link_5_link_6"],
        ["link_4", "link_5", "link_4_link_5"],
        ["link_3", "link_4", "link_3_link_4"],
        ["link_2", "link_3", "link_2_link_3"],
        ["link_1", "link_2", "link_1_link_2"],
        ["base_link", "link_1", "base_link_link_1"],
        ["world", "base_link", "world_base_link"]
    ]

    property Connections _conn: Connections {
        target: root.frameTransformer
        function onTransformsChanged() { root._refresh() }
    }

    function _refresh() {
        if (!root.frameTransformer)
            return
        let allReady = true
        for (const e of root._edges) {
            if (root.frameTransformer.canTransform(e[0], e[1])) {
                const tr = root.frameTransformer.lookupTransform(e[0], e[1]).transform
                root[e[2] + "_p"] = Qt.vector3d(tr.translation.x, tr.translation.y, tr.translation.z)
                root[e[2] + "_q"] = Qt.quaternion(tr.rotation.w, tr.rotation.x, tr.rotation.y, tr.rotation.z)
            } else {
                allReady = false
            }
        }
        root.transformsReady = allReady
    }
}
