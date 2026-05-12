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
    }
}

void QRos2ServiceClientBase::setCallPending(bool pending)
{
    if (m_isCallPending != pending) {
        m_isCallPending = pending;
        emit isCallPendingChanged();
    }
}

QT_END_NAMESPACE
