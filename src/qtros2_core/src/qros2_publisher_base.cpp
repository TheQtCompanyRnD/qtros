// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include <qtros2_core/qros2_publisher_base.hpp>

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
