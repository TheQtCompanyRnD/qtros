// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2actionclientbase_p.h"
#include "qros2node_p.h"
#include <QDebug>

/*!
    \qmltype ActionClientBase
    \inqmlmodule QtRos2.Core
    \brief Abstract base for all generated ROS 2 action client types.

    ActionClientBase is not creatable directly. Use a generated action
    client type.

    \inherits Entity
*/

/*!
    \qmlproperty bool ActionClientBase::isServerReady

    \c true when the action server is available on \l topic.
*/

/*!
    \qmlproperty int ActionClientBase::state

    The current action state as a \c ActionClientBase.ActionState
    enum value:
    \list
        \li \c ActionClientBase.Idle — no active goal
        \li \c ActionClientBase.Requested — goal sent, awaiting acceptance
        \li \c ActionClientBase.Accepted — goal accepted by the server
        \li \c ActionClientBase.Rejected — goal was rejected
        \li \c ActionClientBase.Canceled — goal was canceled
        \li \c ActionClientBase.Succeeded — goal completed successfully
        \li \c ActionClientBase.Aborted — server aborted the goal
    \endlist
*/

/*!
    \qmlmethod void ActionClientBase::cancelGoal()

    Requests cancellation of the currently active goal.
    Has no effect when \l state is \c ActionClientBase.Idle.
*/

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
