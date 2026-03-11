// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef QROS2_SUBSCRIBERBASE_P_H
#define QROS2_SUBSCRIBERBASE_P_H

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
#include "qros2node_p.h"

QT_BEGIN_NAMESPACE

class Q_ROS2CORE_EXPORT QRos2SubscriberBase : public QRos2Entity
{
    Q_OBJECT
    QML_NAMED_ELEMENT(ROS2SubscriberBase)
    QML_UNCREATABLE("Abstract")

    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)

public:
    explicit QRos2SubscriberBase(QObject* parent = nullptr);

    bool connected() const { return m_connected; }

Q_SIGNALS:
    void connectedChanged();

protected:
    void setConnected(bool connected);

    bool m_connected = false;
};

QT_END_NAMESPACE

#endif // QROS2_SUBSCRIBERBASE_P_H
