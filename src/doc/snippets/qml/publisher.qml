// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

//![0]
import QtQuick
import QtQuick.Controls
import QtRos2.GeometryMsgs

Window {
    width: 400
    height: 200
    visible: true

    Node {
        id: rosNode
        nodeName: "hello_node"

        PoseStampedPublisher {
            id: posePublisher
            topic: "/hello_pose"
        }
    }

    Button {
        anchors.centerIn: parent
        text: "Publish"
        enabled: rosNode.initialized
        onClicked: posePublisher.publish({
            header: { frameId: "map" },
            pose: {
                position:    { x: 1.0, y: 2.0, z: 0.5 },
                orientation: { x: 0.0, y: 0.0, z: 0.0, w: 1.0 }
            }
        })
    }
}
//![0]
