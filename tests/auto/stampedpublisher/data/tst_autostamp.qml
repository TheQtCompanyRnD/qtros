// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick
import QtTest
import QtRos2.Core as Ros2
import QtRos2.GeometryMsgs as Geom

// End-to-end demonstration of the PoseStampedPublisher autoStamp behaviors,
// driven entirely through the public QML API: publish on one topic, receive on
// another, and inspect header.stamp on the delivered message. The ROS executor
// spins on its own thread and subscriber callbacks are delivered to this (the
// Qt) thread via a queued connection, so tryVerify just needs to spin the event
// loop until the message arrives.
TestCase {
    id: tc
    name: "AutoStamp"

    property int seq: 0

    Ros2.Node {
        id: node
        nodeName: "tst_autostamp_node"

        Geom.PoseStampedPublisher {
            id: pub
            topic: "/tst_autostamp"
        }
        Geom.PoseStampedSubscriber {
            id: sub
            topic: "/tst_autostamp"
        }
    }

    function initTestCase() {
        tryVerify(() => node.initialized, 5000, "node failed to initialize")
        // Wait for publisher and subscriber to discover each other, so the first
        // published message isn't dropped before the match completes.
        tryVerify(() => pub.subscriberCount > 0, 5000, "pub/sub never matched")
    }

    // Publish msg (tagging it with a unique frameId) and wait until exactly that
    // message has been received, so assertions read the message we just sent
    // regardless of delivery timing. autoStamp only touches header.stamp, so the
    // frameId tag survives untouched.
    function publishAndReceive(msg) {
        msg.header = msg.header || ({})
        msg.header.frameId = "tok" + (++seq)
        pub.publish(msg)
        tryVerify(() => sub.message.header.frameId === msg.header.frameId, 5000,
                  "message not received")
    }

    // autoStamp on: an explicitly-set stamp is forwarded unchanged.
    function test_1_forwardsExplicitStamp() {
        pub.autoStamp = true
        publishAndReceive({ header: { stamp: { sec: 123, nanosec: 456 } } })
        compare(sub.message.header.stamp.sec, 123)
        compare(sub.message.header.stamp.nanosec, 456)
    }

    // autoStamp on: a zero stamp is filled from the node clock at publish time.
    function test_2_autoFillsZeroStamp() {
        pub.autoStamp = true
        publishAndReceive({}) // no stamp set
        verify(sub.message.header.stamp.sec > 0,
               "stamp was not auto-filled from the node clock")
    }

    // autoStamp off: a zero stamp stays zero (caller keeps full control).
    function test_3_disabledLeavesZero() {
        pub.autoStamp = false
        publishAndReceive({}) // no stamp set
        compare(sub.message.header.stamp.sec, 0)
        compare(sub.message.header.stamp.nanosec, 0)
    }
}
