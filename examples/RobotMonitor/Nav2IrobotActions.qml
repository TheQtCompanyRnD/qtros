// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtRos2.Imported.Nav2Msgs
import QtRos2.Imported.IrobotCreateMsgs

QtObject {
    id: root

    property var node

    readonly property var navigationStatus: _navigateToPoseAction.state
    readonly property var navigationFeedback: _navigateToPoseAction.feedback
    readonly property var dockStatus: _dockActionClient.state
    readonly property var dockFeedback: _dockActionClient.feedback
    readonly property var undockStatus: _undockActionClient.state

    property NavigateToPoseActionClient _navigateToPoseAction: NavigateToPoseActionClient {
        node: root.node
        topic: "navigate_to_pose"
    }

    property DockActionClient _dockActionClient: DockActionClient {
        node: root.node
        topic: "dock"
    }

    property UndockActionClient _undockActionClient: UndockActionClient {
        node: root.node
        topic: "undock"
    }

    function navigateToPose(p, yaw) {
        const q = Qt.quaternion(
            Math.cos(yaw / 2), 0, 0, Math.sin(yaw / 2))
        _navigateToPoseAction.sendGoal({
            "pose": {
                "header": { "frameId": "map", "stamp": { "sec": 0, "nanosec": 0 } },
                "pose": {
                    "position": p,
                    "orientation": { "w": q.scalar, "x": q.x, "y": q.y, "z": q.z }
                },
                "behaviorTree": ""
            }
        })
    }

    function dock() { _dockActionClient.sendGoal() }
    function undock() { _undockActionClient.sendGoal() }
}
