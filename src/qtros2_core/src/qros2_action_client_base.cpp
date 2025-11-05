// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include <qtros2_core/qros2_action_client_base.hpp>
#include <qtros2_core/qros2_node.hpp>
#include <QDebug>

QRos2ActionClientBase::QRos2ActionClientBase(QObject* parent)
    : QRos2Entity(parent)
{
}

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
