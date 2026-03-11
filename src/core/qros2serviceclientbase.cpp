// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2serviceclientbase_p.h"
#include <QDebug>

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
