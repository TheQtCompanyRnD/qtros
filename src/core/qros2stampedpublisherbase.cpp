// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2stampedpublisherbase_p.h"

#ifndef Q_QDOC
#include <rclcpp/rclcpp.hpp>
#endif

QT_BEGIN_NAMESPACE

/*!
    \qmltype StampedPublisherBase
    \inqmlmodule QtRos2.Core
    \brief Abstract base for generated publishers of header-stamped messages.

    StampedPublisherBase is not creatable directly. It is the base of every
    generated publisher whose message carries a \c std_msgs/Header as its
    first field (e.g. \l PoseStampedPublisher, \l LaserScanPublisher). It adds
    automatic population of \c header.stamp on top of \l PublisherBase.

    \inherits PublisherBase
*/

QRos2StampedPublisherBase::QRos2StampedPublisherBase(QObject* parent)
    : QRos2PublisherBase(parent)
{
}

/*!
    \qmlproperty bool StampedPublisherBase::autoStamp

    If \c true (the default), the publisher fills the outgoing message's
    \c header.stamp with the node clock time at publish time — but only when
    the stamp has not already been set (i.e. it is still zero). A stamp that
    was assigned explicitly, or forwarded from an incoming message (as in a
    relay), is preserved.

    Set to \c false to take full control of the timestamp, e.g. to guarantee
    pass-through of an upstream sensor acquisition time.

    The timestamp comes from the ROS node clock, so it honors \c use_sim_time
    (simulation / rosbag playback publishing \c /clock) rather than wall-clock
    time.
*/
void QRos2StampedPublisherBase::setAutoStamp(bool autoStamp)
{
    if (m_autoStamp == autoStamp) return;
    m_autoStamp = autoStamp;
    emit autoStampChanged();
}

/*!
    Fills \a stamp with the node clock time when \l autoStamp is enabled and
    \a stamp is still zero. No-op otherwise, so an explicitly-set or forwarded
    stamp is preserved.
*/
void QRos2StampedPublisherBase::applyAutoStamp(builtin_interfaces::msg::Time& stamp) const
{
    if (!m_autoStamp)
        return;
    // Preserve an explicitly-set or forwarded stamp; only fill an unset (zero) one.
    if (stamp.sec != 0 || stamp.nanosec != 0)
        return;
    if (!node() || !node()->rosNode())
        return;
    stamp = node()->rosNode()->now();
}

QT_END_NAMESPACE
