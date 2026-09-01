// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2entity_p.h"
#include "qros2node_p.h"
#include <QDebug>

/*!
    \qmltype Entity
    \inqmlmodule QtRos2.Core
    \inherits NodeChild
    \brief Abstract base for all ROS 2 publisher, subscriber, service-client,
    and action-client types.

    Entity is not creatable directly. It exposes the \l topic and \l qos
    properties that all concrete topic-based types inherit, in addition
    to the \l {NodeChild::node}{node} attachment from \l NodeChild.
*/

/*!
    \qmlproperty string Entity::topic

    The ROS 2 topic or service name this entity publishes to, subscribes
    from, or calls. Changing this property reconnects the entity to the
    new topic.
*/

/*!
    \qmlproperty QRos2QoS Entity::qos

    The Quality-of-Service profile for this entity. Changes take effect
    on the next reconnect.
*/

QT_BEGIN_NAMESPACE

QRos2Entity::QRos2Entity(QObject* parent)
    : QRos2NodeChild(parent)
{
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

void QRos2Entity::setQos(const QRos2QoS& qos)
{
    m_qos = qos;
    emit qosChanged();

    if (m_node && m_node->rosNode()) {
        setupConnection();
    }
}

QT_END_NAMESPACE
