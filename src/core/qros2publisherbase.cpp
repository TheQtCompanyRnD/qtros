// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2publisherbase_p.h"

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
