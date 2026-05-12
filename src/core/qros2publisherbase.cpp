// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2publisherbase_p.h"

/*!
    \qmltype PublisherBase
    \inqmlmodule QtRos2.Core
    \brief Abstract base for all generated ROS 2 publisher types.

    PublisherBase is not creatable directly. Use a generated publisher
    type such as \c {TimePublisher} from \c {QtRos2.BuiltinInterfaces}.

    \inherits Entity
*/

/*!
    \qmlproperty int PublisherBase::subscriberCount

    The number of subscribers currently listening on \l topic.
    Updated periodically by a background health-check timer.
*/

QT_BEGIN_NAMESPACE

QRos2PublisherBase::QRos2PublisherBase(QObject* parent)
    : QRos2Entity(parent)
{
}

void QRos2PublisherBase::setSubscriberCount(int count)
{
    if (m_subscriberCount == count) return;

    m_subscriberCount = count;
    emit subscriberCountChanged();
}

QT_END_NAMESPACE
