// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include <qtros2_core/qros2_subscriber_base.hpp>

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
