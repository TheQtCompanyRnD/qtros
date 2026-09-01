// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtRos2.StdSrvs

Window {
    id: root
    width: 440
    height: 320
    visible: true
    title: `Service client ${lampClient.topic}`

    Node {
        id: rosNode
        nodeName: "simple_service_client_node"

        SetBoolServiceClient {
            id: lampClient
            topic: topicField.text

            // Desired lamp state: every change of the switch calls the
            // service automatically (autoCall is on by default). If the
            // server is not up yet or a call is in flight, the latest
            // value is applied as soon as possible.
            request: lampSwitch.checked
        }
    }

    GridLayout {
        columns: 2
        columnSpacing: 10
        anchors.fill: parent
        anchors.margins: 12

        Label {
            text: rosNode.initialized
                  ? (lampClient.isServiceReady ? qsTr("Service available")
                                               : qsTr("Waiting for service..."))
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

        Switch {
            id: lampSwitch
            text: qsTr("Lamp")
            Layout.columnSpan: 2
        }

        Label {
            text: qsTr("Result")
            font.bold: true
        }
        Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: lampClient.response.message
                  ? `${lampClient.response.success ? qsTr("OK") : qsTr("FAILED")}: ${lampClient.response.message}`
                  : qsTr("Flip the switch to call the service.")
            color: !lampClient.response.message || lampClient.response.success
                   ? palette.text : "firebrick"
        }

        Label {
            text: qsTr("Serve with")
            font.bold: true
        }
        Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: qsTr("Run the Simple Service example with the same topic.")
        }

        Item { Layout.columnSpan: 2; Layout.fillHeight: true }
    }
}
