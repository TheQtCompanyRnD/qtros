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

    property string lastResponse: qsTr("Press On or Off to call the service.")

    Node {
        id: rosNode
        nodeName: "simple_service_client_node"

        SetBoolServiceClient {
            id: lampClient
            topic: topicField.text
        }
    }

    function switchLamp(on) {
        root.lastResponse = qsTr("Calling...")
        // callService() returns a JS promise that resolves with the
        // std_srvs/SetBool response (success, message).
        lampClient.callService(on).then(response => {
            root.lastResponse =
                `success: ${response.success}\nmessage: "${response.message}"`
        }, error => {
            root.lastResponse = qsTr("Call failed: ") + error
        })
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

        Button {
            text: qsTr("Turn lamp on")
            enabled: lampClient.isServiceReady && !lampClient.isCallPending
            onClicked: root.switchLamp(true)
        }
        Button {
            text: qsTr("Turn lamp off")
            enabled: lampClient.isServiceReady && !lampClient.isCallPending
            onClicked: root.switchLamp(false)
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

        TextArea {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            Layout.fillHeight: true
            readOnly: true
            wrapMode: TextEdit.Wrap
            text: root.lastResponse
        }
    }
}
