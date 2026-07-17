// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2serviceserverbase_p.h"
#include <QDebug>

/*!
    \qmltype ServiceServerBase
    \inqmlmodule QtRos2.Core
    \brief Abstract base for all generated ROS 2 service server types.

    ServiceServerBase is not creatable directly. Use a generated
    service server type such as \c {TriggerServiceServer} from
    \c {QtRos2.StdSrvs}.

    \inherits Entity
*/

/*!
    \qmlproperty var ServiceServerBase::handler

    A JavaScript function invoked (on the GUI thread) for every incoming
    request: \c {(request, reply) => response}.

    The handler may respond in one of two ways:
    \list
    \li \e synchronously — return the response value. For services with
        a multi-field response, return an object with the response
        fields, e.g. \c {({ success: true, message: "ok" })}. For
        services with an empty response, return any value other than
        \c undefined to acknowledge the request.
    \li \e deferred — return \c undefined (i.e. no \c return statement)
        and later call \c {reply.send(response)} when the work is done.
        Use this for requests that take time to complete.
    \endlist

    If no handler is set (or the handler throws), a default-constructed
    response is sent so callers do not block indefinitely.
*/

/*!
    \qmlproperty bool ServiceServerBase::active

    \c true while the service is created and advertised on \l topic.
*/

QT_BEGIN_NAMESPACE

QRos2ServiceServerBase::QRos2ServiceServerBase(QObject* parent)
    : QRos2Entity(parent)
{
}

void QRos2ServiceServerBase::setHandler(const QJSValue& handler)
{
    if (m_handler.strictlyEquals(handler))
        return;
    if (!handler.isCallable() && !handler.isUndefined() && !handler.isNull())
        qWarning() << "ServiceServerBase: handler is not callable";
    m_handler = handler;
    emit handlerChanged();
}

void QRos2ServiceServerBase::setActive(bool active)
{
    if (m_active != active) {
        m_active = active;
        emit activeChanged();
    }
}

QT_END_NAMESPACE
