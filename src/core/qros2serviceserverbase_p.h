// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef QROS2_SERVICESERVERBASE_P_H
#define QROS2_SERVICESERVERBASE_P_H

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
#include <QJSValue>

QT_BEGIN_NAMESPACE

class Q_ROS2CORE_EXPORT QRos2ServiceServerBase : public QRos2Entity
{
    Q_OBJECT
    QML_NAMED_ELEMENT(ServiceServerBase)
    QML_UNCREATABLE("QRos2ServiceServerBase is abstract")

    Q_PROPERTY(QJSValue handler READ handler WRITE setHandler NOTIFY handlerChanged)
    Q_PROPERTY(bool active READ isActive NOTIFY activeChanged)

public:
    explicit QRos2ServiceServerBase(QObject* parent = nullptr);
    virtual ~QRos2ServiceServerBase() = default;

    QJSValue handler() const { return m_handler; }
    void setHandler(const QJSValue& handler);

    bool isActive() const { return m_active; }

Q_SIGNALS:
    void handlerChanged();
    void activeChanged();

protected:
    // Called by derived class when the rcl service is created/destroyed
    void setActive(bool active);

    QJSValue m_handler;
    bool m_active = false;
};

QT_END_NAMESPACE

#endif // QROS2_SERVICESERVERBASE_P_H
