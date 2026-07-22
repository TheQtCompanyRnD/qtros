// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2actionserverbase_p.h"

/*!
    \qmltype ActionServerBase
    \inqmlmodule QtRos2.Core
    \brief Abstract base for all generated ROS 2 action server types.

    ActionServerBase is not creatable directly. Use a generated action
    server type such as \c {SpeakActionServer} from a message module.

    A generated server advertises an action on \l topic and, for each
    incoming goal, emits a \c goalReceived signal carrying the goal
    payload and a per-goal \e handle object. QML uses the handle to
    publish feedback, complete the goal (\c succeed / \c abort /
    \c canceled) and observe cancellation requests.

    \inherits Entity
*/

/*!
    \qmlproperty bool ActionServerBase::active

    \c true while the action server is created and advertised on \l topic.
*/

QT_BEGIN_NAMESPACE

QRos2ActionServerBase::QRos2ActionServerBase(QObject* parent)
    : QRos2Entity(parent)
{
}

void QRos2ActionServerBase::setActive(bool active)
{
    if (m_active != active) {
        m_active = active;
        emit activeChanged();
    }
}

QT_END_NAMESPACE
