// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#pragma once

#include <qtros2_core/qros2_entity.hpp>
#include <qtros2_core/qros2_node.hpp>

class QRos2PublisherBase : public QRos2Entity
{
    Q_OBJECT
    QML_NAMED_ELEMENT(ROS2PublisherBase)
    QML_UNCREATABLE("Abstract")

    Q_PROPERTY(int subscriberCount READ subscriberCount NOTIFY subscriberCountChanged)

public:
    explicit QRos2PublisherBase(QObject* parent = nullptr);

    int subscriberCount() const { return m_subscriberCount; }

Q_SIGNALS:
    void subscriberCountChanged();

protected:
    void setSubscriberCount(int count);

    int m_subscriberCount = 0;
};
