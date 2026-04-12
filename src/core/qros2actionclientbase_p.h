// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef QROS2_ACTIONCLIENTBASE_P_H
#define QROS2_ACTIONCLIENTBASE_P_H

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
#include <QObject>
#include <QString>
#include <QFuture>
#include <QPromise>
#include <exception>
#include <stdexcept>

QT_BEGIN_NAMESPACE

class Q_ROS2CORE_EXPORT QRos2ActionClientBase : public QRos2Entity
{
    Q_OBJECT
    QML_NAMED_ELEMENT(Ros2ActionClientBase)
    QML_UNCREATABLE("Abstract")

    Q_PROPERTY(bool isServerReady READ isServerReady NOTIFY isServerReadyChanged)
    Q_PROPERTY(int state READ state NOTIFY stateChanged)

public:
    explicit QRos2ActionClientBase(QObject* parent = nullptr);
    virtual ~QRos2ActionClientBase();

    enum class ActionState {
        Idle = 0,
        Requested,
        Accepted,
        Rejected,
        Canceled,
        Succeeded,
        Aborted
    };
    Q_ENUM(ActionState)

    bool isServerReady() const { return m_serverReady; }
    int state() const { return static_cast<int>(m_state); }

    Q_INVOKABLE virtual void cancelGoal() = 0;

Q_SIGNALS:
    void isServerReadyChanged();
    void stateChanged();

protected:
    void setServerReady(bool ready);
    void setState(ActionState newState);

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

    bool m_serverReady = false;
    ActionState m_state = ActionState::Idle;
};

QT_END_NAMESPACE

#endif // QROS2_ACTIONCLIENTBASE_P_H
