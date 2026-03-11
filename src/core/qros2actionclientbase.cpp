// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2actionclientbase_p.h"
#include "qros2node_p.h"
#include <QDebug>

QT_BEGIN_NAMESPACE

QRos2ActionClientBase::QRos2ActionClientBase(QObject* parent)
    : QRos2Entity(parent)
{
}

QRos2ActionClientBase::~QRos2ActionClientBase() {}

void QRos2ActionClientBase::setServerReady(bool ready)
{
    if (m_serverReady != ready) {
        m_serverReady = ready;
        emit isServerReadyChanged();
    }
}

void QRos2ActionClientBase::setState(ActionState newState)
{
    if (m_state == newState) return;
    m_state = newState;
    emit stateChanged();
}

QT_END_NAMESPACE
