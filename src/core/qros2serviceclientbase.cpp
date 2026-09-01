// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2serviceclientbase_p.h"
#include <QDebug>

/*!
    \qmltype ServiceClientBase
    \inqmlmodule QtRos2.Core
    \brief Abstract base for all generated ROS 2 service client types.

    ServiceClientBase is not creatable directly. Use a generated
    service client type such as \c {GetAvailableStatesServiceClient}
    from \c {QtRos2.LifecycleMsgs}.

    \inherits Entity
*/

/*!
    \qmlproperty bool ServiceClientBase::isServiceReady

    \c true when the service server is available on \l topic.
*/

/*!
    \qmlproperty bool ServiceClientBase::isCallPending

    \c true while a service call is in progress and a response is awaited.
*/

/*!
    \qmlproperty bool ServiceClientBase::autoCall

    If \c true (the default), assigning the \c request property of a
    generated service client schedules a service call at the end of the
    current event-loop iteration. Multiple assignments per iteration
    coalesce into one call. While the service is unavailable or a call
    is already in flight, the latest request value is remembered and
    dispatched as soon as possible, so a binding on \c request behaves
    like desired state that is reconciled with the server.

    If \c false, writes to \c request only store the value and
    \c callService() must be called explicitly; when \c autoCall is
    later enabled, the most recent stored request (if any was written)
    is dispatched, so gating \c autoCall gates dispatch, not intent.
    Auto-calls happen only when the \c request property is written, so
    clients used purely imperatively are unaffected by this property.
*/

QT_BEGIN_NAMESPACE

QRos2ServiceClientBase::QRos2ServiceClientBase(QObject* parent)
    : QRos2Entity(parent)
{
}

void QRos2ServiceClientBase::setServiceReady(bool ready)
{
    if (m_serviceReady != ready) {
        m_serviceReady = ready;
        emit isServiceReadyChanged();
        if (ready)
            scheduleStoredCallAttempt();
    }
}

void QRos2ServiceClientBase::setCallPending(bool pending)
{
    if (m_isCallPending != pending) {
        m_isCallPending = pending;
        emit isCallPendingChanged();
        if (!pending)
            scheduleStoredCallAttempt();
    }
}

void QRos2ServiceClientBase::setAutoCall(bool autoCall)
{
    if (m_autoCall == autoCall)
        return;
    m_autoCall = autoCall;
    emit autoCallChanged();
    if (autoCall)
        scheduleStoredCallAttempt();
}

void QRos2ServiceClientBase::requestCall()
{
    // Remember the write even while autoCall is off: enabling autoCall later
    // dispatches the latest stored request (desired state is reconciled from
    // the moment reconciliation is switched on).
    m_requestDirty = true;
    if (!m_autoCall)
        return;
    scheduleStoredCallAttempt();
}

void QRos2ServiceClientBase::scheduleStoredCallAttempt()
{
    if (m_attemptScheduled || !m_requestDirty || !m_autoCall)
        return;
    m_attemptScheduled = true;
    QMetaObject::invokeMethod(this, &QRos2ServiceClientBase::attemptStoredCall,
                              Qt::QueuedConnection);
}

void QRos2ServiceClientBase::attemptStoredCall()
{
    m_attemptScheduled = false;
    if (!m_requestDirty || !m_autoCall)
        return;
    // Not ready or busy: keep the dirty flag; setServiceReady() and
    // setCallPending() re-schedule the attempt when the state clears.
    if (!m_serviceReady || m_isCallPending)
        return;
    m_requestDirty = false;
    callStoredRequest();
}

QT_END_NAMESPACE
