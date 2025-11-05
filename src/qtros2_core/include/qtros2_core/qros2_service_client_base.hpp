// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#pragma once

#include <qtros2_core/qros2_entity.hpp>
#include <rclcpp/rclcpp.hpp>
#include <QObject>
#include <QString>
#include <QFuture>
#include <QPromise>
#include <exception>
#include <stdexcept>

class QRos2ServiceClientBase : public QRos2Entity
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("QRos2ServiceClientBase is abstract")

    Q_PROPERTY(bool isServiceReady READ isServiceReady NOTIFY isServiceReadyChanged)
    Q_PROPERTY(bool isCallPending READ isCallPending NOTIFY isCallPendingChanged)

public:
    explicit QRos2ServiceClientBase(QObject* parent = nullptr);
    virtual ~QRos2ServiceClientBase() = default;

    bool isServiceReady() const { return m_serviceReady; }
    bool isCallPending() const { return m_isCallPending; }

Q_SIGNALS:
    void isServiceReadyChanged();
    void isCallPendingChanged();

protected:
    // Must be called by derived class when client is created
    void setServiceReady(bool ready);

    void setCallPending(bool pending);

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

};
