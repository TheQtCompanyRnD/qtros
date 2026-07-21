// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick
import QtTest
import QtRos2.Core

TestCase {
    id: root
    name: "Parameters"

    Node {
        id: serverNode
        nodeName: "param_server_node"

        Parameter {
            id: volume
            name: "volume"
            value: 0.25
            minimum: 0.0
            maximum: 1.0
            description: "test volume"
        }

        Parameter {
            id: constParam
            name: "fixed"
            value: "immutable"
            readOnly: true
        }

        Parameter {
            id: late
            name: "late"   // Auto type, no value: declaration is deferred
        }

        // App-authoritative bound value: src is the source of truth,
        // valueEdited routes external sets back into it.
        property real src: 0.25
        Parameter {
            id: bound
            name: "bound"
            value: serverNode.src
            onValueEdited: (v) => serverNode.src = v
        }
    }

    Node {
        id: clientNode
        nodeName: "param_client_node"

        RemoteParameter {
            id: remoteVolume
            remoteNode: "/param_server_node"
            name: "volume"
        }
        RemoteParameter {
            id: remoteFixed
            remoteNode: "/param_server_node"
            name: "fixed"
        }
        RemoteParameter {
            id: remoteBound
            remoteNode: "/param_server_node"
            name: "bound"
        }
        // Targets a node that does not exist yet (created in test_late_remote)
        RemoteParameter {
            id: remoteLate
            remoteNode: "/late_server_node"
            name: "x"
        }
    }

    SignalSpy { id: editedSpy; target: volume; signalName: "valueEdited" }
    SignalSpy { id: failedSpy; target: remoteVolume; signalName: "setFailed" }
    SignalSpy { id: fixedFailedSpy; target: remoteFixed; signalName: "setFailed" }

    function initTestCase() {
        tryVerify(() => serverNode.initialized, 15000)
        tryVerify(() => clientNode.initialized, 15000)
    }

    function test_a_declared_and_initial_get() {
        tryVerify(() => volume.declared, 15000)
        tryVerify(() => remoteVolume.ready, 30000)
        tryCompare(remoteVolume, "reported", 0.25, 15000)
    }

    function test_b_set_via_desired_value() {
        remoteVolume.value = 0.5
        tryCompare(remoteVolume, "reported", 0.5, 15000)   // via /parameter_events
        compare(volume.value, 0.5)
        verify(editedSpy.count >= 1)
        compare(editedSpy.signalArguments[editedSpy.count - 1][0], 0.5)
    }

    function test_c_range_rejection() {
        const before = volume.value
        remoteVolume.value = 2.0    // outside [0, 1]: rclcpp rejects
        failedSpy.wait(15000)
        compare(volume.value, before)
        tryCompare(remoteVolume, "pending", false, 15000)  // no retry loop
        compare(remoteVolume.reported, before)
    }

    function test_d_readonly_rejected() {
        tryVerify(() => remoteFixed.ready, 30000)
        remoteFixed.value = "hacked"
        fixedFailedSpy.wait(15000)
        compare(constParam.value, "immutable")
    }

    function test_e_bound_value_echo() {
        tryVerify(() => remoteBound.ready, 30000)
        remoteBound.value = 0.75
        tryCompare(remoteBound, "reported", 0.75, 15000)
        tryCompare(serverNode, "src", 0.75, 15000)
        compare(bound.value, 0.75)   // binding echoed the edit back; stable
    }

    function test_f_type_deferral() {
        compare(late.declared, false)   // Auto + no value: still deferred
        late.value = 42
        tryVerify(() => late.declared, 15000)
    }

    function test_g_late_remote_reconciliation() {
        // Desired state written while the remote node does not exist yet.
        remoteLate.value = 7
        verify(!remoteLate.ready)
        const server = Qt.createQmlObject(`
            import QtRos2.Core
            Node {
                nodeName: "late_server_node"
                Parameter { name: "x"; value: 0 }
            }`, root, "lateServer")
        tryCompare(remoteLate, "reported", 7, 30000)   // applied once ready
        server.destroy()
    }
}
