// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtRos2.StdSrvs

Window {
    id: root
    width: 480
    height: 440
    visible: true
    title: `Service ${lampService.topic}`

    property bool lampOn: false
    property int requestCount: 0
    property string lastRequest: qsTr("No requests received yet.")

    Node {
        id: rosNode
        nodeName: "simple_service_node"

        SetBoolServiceServer {
            id: lampService
            topic: topicField.text

            // The handler is invoked on the GUI thread for every incoming
            // request. For std_srvs/SetBool the request payload is a plain
            // bool; `reply` allows answering later when the work takes time.
            handler: (request, reply) => {
                ++root.requestCount
                root.lampOn = request
                root.lastRequest = `Request #${root.requestCount}: data=${request}`

                if (delaySwitch.checked) {
                    // Deferred style: return undefined now and answer from
                    // replyTimer once the "work" is done. The ROS executor is
                    // not blocked while the reply is pending.
                    replyTimer.pendingReplies.push(reply)
                    replyTimer.restart()
                    return
                }

                // Synchronous style: return the response object directly.
                return {
                    success: true,
                    message: `lamp is now ${request ? "on" : "off"}`
                }
            }
        }
    }

    Timer {
        id: replyTimer
        interval: 1000
        property var pendingReplies: []
        onTriggered: {
            for (const reply of pendingReplies) {
                reply.send({
                    success: true,
                    message: `lamp is now ${root.lampOn ? "on" : "off"} (delayed reply)`
                })
            }
            pendingReplies = []
        }
    }

    GridLayout {
        columns: 2
        columnSpacing: 10
        anchors.fill: parent
        anchors.margins: 12

        Label {
            text: rosNode.initialized
                  ? (lampService.active ? qsTr("Service ready") : qsTr("Service inactive"))
                  : qsTr("Initializing ROS 2 Node...")
            font.bold: true
            Layout.columnSpan: 2
        }

        Label {
            text: qsTr("Topic")
            font.bold: true
        }
        TextField {
            id: topicField
            Layout.fillWidth: true
            text: "/simple_service_lamp"
        }

        Label {
            text: qsTr("Lamp")
            font.bold: true
        }
        Rectangle {
            width: 48
            height: 48
            radius: 24
            color: root.lampOn ? "gold" : "dimgray"
            border.color: "black"
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Switch {
            id: delaySwitch
            text: qsTr("Delay the response by 1 s (deferred reply)")
            Layout.columnSpan: 2
        }

        Label {
            text: qsTr("Requests received")
        }
        Label {
            text: root.requestCount
        }

        Label {
            text: qsTr("Call with")
            font.bold: true
        }
        TextField {
            Layout.fillWidth: true
            readOnly: true
            text: `ros2 service call ${lampService.topic} std_srvs/srv/SetBool "{data: true}"`
            onTextChanged: cursorPosition = 0
        }

        TextArea {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            Layout.fillHeight: true
            readOnly: true
            wrapMode: TextEdit.Wrap
            text: root.lastRequest
        }
    }
}
