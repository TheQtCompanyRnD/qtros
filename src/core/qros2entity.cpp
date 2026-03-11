// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2entity_p.h"
#include "qros2node_p.h"
#include <QDebug>

QT_BEGIN_NAMESPACE

QRos2Entity::QRos2Entity(QObject* parent)
    : QObject(parent)
{
}

QRos2Entity::~QRos2Entity()
{
    if (m_node) {
        m_node->unregisterEntity(this);
    }
}

void QRos2Entity::setTopic(const QString& topic)
{
    if (m_topic == topic) return;

    m_topic = topic;
    emit topicChanged();

    if (m_node && m_node->rosNode()) {
        setupConnection();
    }
}

void QRos2Entity::setNode(QRos2Node* node)
{
    if (m_node == node) return;

    if (m_node) {
        m_node->unregisterEntity(this);
    }

    m_node = node;

    if (m_node) {
        m_node->registerEntity(this);
    }

    setupConnection();

    emit nodeChanged();
}

void QRos2Entity::setQos(const QRos2QoS& qos)
{
    m_qos = qos;
    emit qosChanged();

    if (m_node && m_node->rosNode()) {
        setupConnection();
    }
}

QT_END_NAMESPACE
