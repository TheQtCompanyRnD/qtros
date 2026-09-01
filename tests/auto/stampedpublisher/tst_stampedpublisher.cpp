// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: BSD-3-Clause

#include <QtRos2Core/private/qros2stampedpublisherbase_p.h>

#include <QtTest/qtest.h>

#include <builtin_interfaces/msg/time.hpp>

// Minimal concrete publisher that exposes the protected applyAutoStamp() so the
// fill-if-zero policy can be tested directly, with no live ROS node or message
// transport (same no-op-hooks approach as tst_nodelifecycle's TestEntity). The
// two cases below both take applyAutoStamp()'s early-out paths, before it ever
// consults the node clock, so no rclcpp context is needed. The auto-fill path
// (zero stamp -> node clock) needs a running node and is covered end-to-end by
// the QML roundtrip test instead.
class TestStampedPublisher : public QRos2StampedPublisherBase
{
    Q_OBJECT
public:
    using QRos2StampedPublisherBase::applyAutoStamp;
protected:
    void setupConnection() override {}
    void clearConnection() override {}
};

class tst_stampedpublisher : public QObject
{
    Q_OBJECT
private slots:
    void forwardsExplicitStamp();
    void disabledLeavesStampZero();
};

// autoStamp must not overwrite a stamp that is already set; it only fills a zero
// stamp. This is what lets a relay forward an upstream/sensor stamp unchanged.
void tst_stampedpublisher::forwardsExplicitStamp()
{
    TestStampedPublisher pub; // autoStamp defaults to true
    QVERIFY(pub.autoStamp());

    builtin_interfaces::msg::Time stamp;
    stamp.sec = 123;
    stamp.nanosec = 456;
    pub.applyAutoStamp(stamp);

    QCOMPARE(stamp.sec, 123);
    QCOMPARE(stamp.nanosec, 456u);
}

// With autoStamp disabled, a zero stamp stays zero (the node clock is never
// consulted), so the caller keeps full control of the timestamp.
void tst_stampedpublisher::disabledLeavesStampZero()
{
    TestStampedPublisher pub;
    pub.setAutoStamp(false);

    builtin_interfaces::msg::Time stamp; // default-constructed: sec = 0, nanosec = 0
    pub.applyAutoStamp(stamp);

    QCOMPARE(stamp.sec, 0);
    QCOMPARE(stamp.nanosec, 0u);
}

QTEST_GUILESS_MAIN(tst_stampedpublisher)

#include "tst_stampedpublisher.moc"
