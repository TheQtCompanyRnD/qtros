// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#pragma once

#include <qtros2_core/qros2_entity.hpp>
#include "qros2_node.hpp"

class QRos2SubscriberBase : public QRos2Entity
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
