// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtRos2.StdSrvs

Window {
    id: root
    width: 480
    height: 500
    visible: true
    title: `Service ${lampService.topic}`

    property int cycles: 0
    readonly property bool burnedOut: cycles >= 10
    property string lastRequest: qsTr("No requests received yet.")

    Node {
        id: rosNode
        nodeName: "simple_service_node"

        SetBoolServiceServer {
            id: lampService
            topic: topicField.text

            // Effects and bookkeeping are imperative, in the signal handler...
            onRequestReceived: request => {
                ++root.cycles
                root.lastRequest = `Request #${root.cycles}: data=${request}`
            }

            // ...while the response is declarative: each request is answered
            // with the current value of this binding. It re-evaluates after
            // request and onRequestReceived update, so root.cycles is already
            // current — the request that burns out the bulb gets the failure.
            response: root.burnedOut
                ? ({ success: false, message: "the bulb is burned out" })
                : ({ success: true, message: `lamp is now ${lampService.request ? "on" : "off"}` })

            // Deferred style, selected by the switch: a callable handler takes
            // precedence over the declarative response. This one parks the
            // reply and answers from the timer below when the "work" is done.
            handler: delaySwitch.checked
                ? (request, reply) => {
                      replyTimer.pendingReplies.push(reply)
                      replyTimer.restart()
                  }
                : undefined
        }
    }

    Timer {
        id: replyTimer
        interval: 1000
        property var pendingReplies: []
        onTriggered: {
            for (const reply of pendingReplies)
                reply.send(lampService.response)   // same declarative value, later
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
            color: root.burnedOut ? "black"
                 : lampService.request ? "gold" : "dimgray"
            border.color: "black"
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Label {
            text: qsTr("Bulb wear")
        }
        RowLayout {
            Label {
                text: root.burnedOut ? qsTr("%1 cycles — burned out!").arg(root.cycles)
                                     : qsTr("%1 of 10 cycles").arg(root.cycles)
            }
            Button {
                text: qsTr("Replace bulb")
                visible: root.burnedOut
                onClicked: root.cycles = 0
            }
        }

        Switch {
            id: delaySwitch
            text: qsTr("Delay the response by 1 s (deferred reply)")
            Layout.columnSpan: 2
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
