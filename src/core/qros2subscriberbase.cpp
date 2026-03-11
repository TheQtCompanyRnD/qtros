// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2subscriberbase_p.h"

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
