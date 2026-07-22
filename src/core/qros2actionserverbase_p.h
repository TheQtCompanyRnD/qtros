// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef QROS2_ACTIONSERVERBASE_P_H
#define QROS2_ACTIONSERVERBASE_P_H

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

QT_BEGIN_NAMESPACE

class Q_ROS2CORE_EXPORT QRos2ActionServerBase : public QRos2Entity
{
    Q_OBJECT
    QML_NAMED_ELEMENT(ActionServerBase)
    QML_UNCREATABLE("QRos2ActionServerBase is abstract")

    Q_PROPERTY(bool active READ isActive NOTIFY activeChanged)

public:
    explicit QRos2ActionServerBase(QObject* parent = nullptr);
    ~QRos2ActionServerBase() override = default;

    bool isActive() const { return m_active; }

Q_SIGNALS:
    void activeChanged();

protected:
    // Called by the derived class when the rcl action server is created/destroyed.
    void setActive(bool active);

    bool m_active = false;
};

QT_END_NAMESPACE

#endif // QROS2_ACTIONSERVERBASE_P_H
