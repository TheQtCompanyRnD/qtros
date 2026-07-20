// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2publisherbase_p.h"

#include <QTimerEvent>

QT_BEGIN_NAMESPACE

/*!
    \qmltype PublisherBase
    \inqmlmodule QtRos2.Core
    \brief Abstract base for all generated ROS 2 publisher types.

    PublisherBase is not creatable directly. Use a generated publisher
    type such as \l TimePublisher from \l QtRos2.BuiltinInterfaces.

    \inherits Entity

    \section1 Automatic publishing

    Generated multi-field publishers (e.g. \l TwistPublisher with its
    \c linear and \c angular properties) store the most recently assigned
    field values and can publish them automatically. Two orthogonal
    properties control \e when a publish happens:

    \list
      \li \l autoPublish — publish whenever any field property changes
          (responsiveness).
      \li \l publishInterval — publish at least this often, in
          milliseconds (liveness / watchdog).
    \endlist

    The two combine into four behaviors:

    \table
      \header
        \li autoPublish
        \li publishInterval
        \li behavior
      \row
        \li \c false
        \li \c 0
        \li Manual only. Call \l publish() (or a typed \c publish(msg)
            overload) explicitly. Field property writes update the
            stored message silently.
      \row
        \li \c true
        \li \c 0
        \li Publish on change (default). Each field property write
            schedules a publish at the end of the current event-loop
            iteration; multiple writes in one iteration coalesce into
            one publish.
      \row
        \li \c false
        \li \c {> 0}
        \li Rate-driven heartbeat. The timer publishes the stored
            message every \c publishInterval ms; intervening property
            writes silently accumulate. Useful for sending a stream
            of state at a fixed rate (e.g. \c cmd_vel for a robot
            base with a watchdog timeout).
      \row
        \li \c true
        \li \c {> 0}
        \li Publish on change \e and at least every \c publishInterval
            ms. Property writes publish immediately (coalesced) and
            also reset the heartbeat timer, so the timer only fires
            when the publisher has been quiet for \c publishInterval
            ms. Useful for state publishers that want low latency on
            changes plus a periodic heartbeat for consumers that watch
            for liveness.
    \endtable

    \section2 Event-loop coalescing

    When \l autoPublish is \c true, assigning a field property does not
    publish immediately. Instead it sets an internal pending flag and,
    on the first such assignment per event-loop iteration, posts a
    queued metacall (\l Qt::QueuedConnection) to \l publish(). Every
    subsequent property assignment in the same iteration finds the flag
    already set and does nothing extra. When the event loop next spins,
    \l publish() runs once with all the accumulated changes in place.

    The batching boundary is therefore one trip through the event loop,
    not one JavaScript expression. A single QTouchEvent that drives
    bindings to four separate field properties produces one publish.
    Updates separated by an awaited signal, a \c QTimer::singleShot(0),
    or a queued cross-thread signal land in different iterations and
    publish independently.
*/

QRos2PublisherBase::QRos2PublisherBase(QObject* parent)
    : QRos2Entity(parent)
{
}

/*!
    \qmlproperty int PublisherBase::subscriberCount

    The number of subscribers currently listening on \l topic.
    Updated periodically by a background health-check timer.
*/
void QRos2PublisherBase::setSubscriberCount(int count)
{
    if (m_subscriberCount == count) return;

    m_subscriberCount = count;
    emit subscriberCountChanged();
}

/*!
    \qmlproperty bool PublisherBase::autoPublish

    If \c true (the default), assigning any field property of a
    publisher schedules a publish at the end of the current
    event-loop iteration. Multiple assignments per iteration coalesce
    into one publish. If \c false, field property writes update the
    stored message silently and \l publish() must be called explicitly.

    Has no effect on empty publisher types, which have no stored state.
*/
void QRos2PublisherBase::setAutoPublish(bool autoPublish)
{
    if (m_autoPublish == autoPublish) return;
    m_autoPublish = autoPublish;
    emit autoPublishChanged();
}

/*!
    \qmlproperty int PublisherBase::publishInterval

    If greater than zero, publish the stored message every
    \c publishInterval milliseconds. Combined with \l autoPublish, the
    timer is reset on each change-driven publish, so the heartbeat
    fires only when the publisher has been quiet for the full interval.
    Defaults to \c 0 (no timer).

    Has no effect on empty publisher types, which have no stored state.
*/
void QRos2PublisherBase::setPublishInterval(int ms)
{
    if (m_publishInterval == ms) return;
    m_publishInterval = ms;
    if (ms > 0)
        m_publishTimer.start(ms, this);
    else
        m_publishTimer.stop();
    emit publishIntervalChanged();
}

/*!
    \qmlmethod void PublisherBase::publish()

    Publishes the stored message state. For empty publisher types this
    is a no-op. Single-field publishers also offer a typed
    \c publish(value) overload that sends a value immediately without
    touching the stored property.

    Calling this clears any pending coalesced publish and, when
    \l publishInterval is greater than zero, restarts the heartbeat
    timer so the next periodic publish is \c publishInterval ms from
    now.
*/
void QRos2PublisherBase::publish()
{
    m_publishPending = false;
    publishStoredState();
    if (m_publishInterval > 0)
        m_publishTimer.start(m_publishInterval, this);
}

/*!
    Generated setters call this after writing m_message to request a
    coalesced publish at the end of the current event-loop iteration.
*/
void QRos2PublisherBase::requestPublish()
{
    m_storedStateWritten = true;
    if (!m_autoPublish || m_publishPending)
        return;
    m_publishPending = true;
    QMetaObject::invokeMethod(this, &QRos2PublisherBase::publish, Qt::QueuedConnection);
}

/*!
    Whether generated setupConnection() should republish the stored state
    after (re)creating the rcl publisher. True only for latched
    (transient_local) topics whose stored state was actually written:
    state bound before node initialization (or before a topic/qos change)
    would otherwise never reach late-joining subscriptions. Volatile
    (command-style) topics are left alone.
*/
bool QRos2PublisherBase::shouldRepublishOnConnect() const
{
    return m_storedStateWritten
        && m_qos.durability() == RMW_QOS_POLICY_DURABILITY_TRANSIENT_LOCAL;
}

/*!
    Overridden by generated publishers to publish their stored state
    (m_message for multi-field, the stored scalar for single-field).
    Empty default is correct for empty messages, which have no stored
    state to flush.
*/
void QRos2PublisherBase::publishStoredState() {}

void QRos2PublisherBase::timerEvent(QTimerEvent* event)
{
    if (event->timerId() == m_publishTimer.timerId()) {
        publish();
    } else {
        QRos2Entity::timerEvent(event);
    }
}

QT_END_NAMESPACE
