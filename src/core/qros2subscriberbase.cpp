// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2subscriberbase_p.h"

/*!
    \qmltype SubscriberBase
    \inqmlmodule QtRos2.Core
    \brief Abstract base for all generated ROS 2 subscriber types.

    SubscriberBase is not creatable directly. Use a generated subscriber
    type such as \c {TimeSubscriber} from \c {QtRos2.BuiltinInterfaces}.

    \inherits Entity
*/

/*!
    \qmlproperty bool SubscriberBase::connected

    \c true when at least one publisher is advertising on \l topic.
    Updated periodically by a background health-check timer.
*/

QT_BEGIN_NAMESPACE

QRos2SubscriberBase::QRos2SubscriberBase(QObject* parent)
    : QRos2Entity(parent)
{
}

void QRos2SubscriberBase::setConnected(bool connected)
{
    if (m_connected == connected) return;

    m_connected = connected;
    emit connectedChanged();
}

QT_END_NAMESPACE
