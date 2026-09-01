// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef QROS2_SERVICECLIENTBASE_P_H
#define QROS2_SERVICECLIENTBASE_P_H

//
//  W A R N I N G
//  -------------
//
// This file is not part of the Qt API.  It exists purely as an
// implementation detail.  This header file may change from version to
// version without notice, or even be removed.
//
// We mean it.
//

#include <QtRos2Core/qtros2coreexports.h>
#include "qros2entity_p.h"
#ifndef Q_QDOC
#include <rclcpp/rclcpp.hpp>
#endif
#include <QObject>
#include <QString>
#include <QFuture>
#include <QPromise>
#include <exception>
#include <stdexcept>

QT_BEGIN_NAMESPACE

class Q_ROS2CORE_EXPORT QRos2ServiceClientBase : public QRos2Entity
{
    Q_OBJECT
    QML_NAMED_ELEMENT(ServiceClientBase)
    QML_UNCREATABLE("QRos2ServiceClientBase is abstract")

    Q_PROPERTY(bool isServiceReady READ isServiceReady NOTIFY isServiceReadyChanged)
    Q_PROPERTY(bool isCallPending READ isCallPending NOTIFY isCallPendingChanged)
    Q_PROPERTY(bool autoCall READ autoCall WRITE setAutoCall NOTIFY autoCallChanged)

public:
    explicit QRos2ServiceClientBase(QObject* parent = nullptr);
    virtual ~QRos2ServiceClientBase() = default;

    bool isServiceReady() const { return m_serviceReady; }
    bool isCallPending() const { return m_isCallPending; }

    bool autoCall() const { return m_autoCall; }
    void setAutoCall(bool autoCall);

Q_SIGNALS:
    void isServiceReadyChanged();
    void isCallPendingChanged();
    void autoCallChanged();

protected:
    // Must be called by derived class when client is created
    void setServiceReady(bool ready);

    void setCallPending(bool pending);

    // Generated setRequest() setters call this to schedule a coalesced
    // auto-call of the stored request at the end of the current event-loop
    // iteration (mirrors QRos2PublisherBase::requestPublish()).
    void requestCall();

    // Overridden by generated clients that have a bindable request property
    // to dispatch the stored request via callService.
    virtual void callStoredRequest() {}

    template<typename T>
    QFuture<T> makeRejectedFuture(const QString& message) const
    {
        QPromise<T> promise;
        promise.setException(makeException(message));
        promise.finish();
        return promise.future();
    }

    static std::exception_ptr makeException(const QString& message)
    {
        return std::make_exception_ptr(std::runtime_error(message.toStdString()));
    }

    bool m_serviceReady = false;
    bool m_isCallPending = false;

private:
    void scheduleStoredCallAttempt();
    void attemptStoredCall();

    bool m_autoCall = true;
    bool m_requestDirty = false;
    bool m_attemptScheduled = false;
};

QT_END_NAMESPACE

#endif // QROS2_SERVICECLIENTBASE_P_H
