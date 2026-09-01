// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2nodechild_p.h"
#include "qros2node_p.h"

/*!
    \qmltype NodeChild
    \inqmlmodule QtRos2.Core
    \brief Abstract base for all items that attach to a Node.

    NodeChild is not creatable directly. It provides the \l node
    attachment and lifecycle shared by every item hosted by a
    \l Node: topic-based entities (\l Entity and its concrete
    publisher/subscriber/client types) and non-topic items such as
    \l Parameter.
*/

/*!
    \qmlproperty Node NodeChild::node

    The \l Node this item is attached to. The item creates its
    underlying ROS 2 connection when \l node becomes initialized.
    Items declared as children of a Node are attached automatically.
*/

QT_BEGIN_NAMESPACE

QRos2NodeChild::QRos2NodeChild(QObject* parent)
    : QObject(parent)
{
}

QRos2NodeChild::~QRos2NodeChild()
{
    if (m_node) {
        m_node->unregisterEntity(this);
    }
}

void QRos2NodeChild::setNode(QRos2Node* node)
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

QT_END_NAMESPACE
