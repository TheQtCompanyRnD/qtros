// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2node_p.h"
#include "qros2context.h"
#include "qros2entity_p.h"

#include <QDebug>
#include <QLoggingCategory>

QT_BEGIN_NAMESPACE

Q_STATIC_LOGGING_CATEGORY(lcNode, "qt.robotics.node")

static QString getDefaultNamespace() { return QStringLiteral("/"); }

QRos2Node::QRos2Node(QObject* parent)
    : QObject(parent)
    , m_healthTimer(this)
{
    m_healthTimer.setInterval(100); // 10 Hz health checks
    m_nodeNamespace = getDefaultNamespace();
    connect(&m_healthTimer, &QTimer::timeout, this, &QRos2Node::updateAllConnectionStates);
}

QRos2Node::~QRos2Node()
{
    shutdownNode();
}

void QRos2Node::setNodeName(const QString& name)
{
    if (m_nodeName == name) return;

    m_nodeName = name;
    emit nodeNameChanged();

    if (!m_nodeName.isEmpty())
        initializeNode();
}

void QRos2Node::setNodeNamespace(const QString& ns)
{
    if (m_nodeNamespace == ns) return;

    m_nodeNamespace = ns;
    emit nodeNamespaceChanged();

    if (!m_nodeName.isEmpty())
        initializeNode();
}

void QRos2Node::componentComplete()
{
    m_componentComplete = true;
    if (!m_nodeName.isEmpty()) {
        // FIXME: Delay the intialization to allow the Context item to initialize first...
        QMetaObject::invokeMethod(this, &QRos2Node::initializeNode, Qt::QueuedConnection);
    }
}

void QRos2Node::initializeNode()
{
    if (!m_componentComplete || m_nodeName.isEmpty())
        return;

    if (!QRos2Context::isInitialized())
        QRos2Context::init();

    if (m_rosNode) {
        shutdownNode();
    }

    try {
        m_rosNode = std::make_shared<rclcpp::Node>(
            m_nodeName.toStdString(),
            m_nodeNamespace.toStdString()
            );

        QRos2Context::instance().executor()->add_node(m_rosNode);

        m_healthTimer.start();

        m_initialized = true;
        emit initializedChanged();

        auto topic_names_and_types = m_rosNode->get_topic_names_and_types();
        qCInfo(lcNode) << "Discovered topics after initialization of node" << m_nodeName << "ns" << m_nodeNamespace << ":";
        for (const auto& [name, types] : topic_names_and_types) {
            QString type_list;
            for (const auto& t : types) {
                if (!type_list.isEmpty())
			type_list += QStringLiteral(", ");
                type_list += QString::fromStdString(t);
            }
            qCInfo(lcNode) << "   " << QString::fromStdString(name) << "types:" << type_list;
        }

        for (auto* entity : std::as_const(m_entities)) {
            entity->setupConnection();
        }

    } catch (const std::exception&) {
        m_initialized = false;
        emit initializedChanged();
    }
}

void QRos2Node::shutdownNode()
{
    if (m_healthTimer.isActive()) {
        m_healthTimer.stop();
    }

    for (auto entity : std::as_const(m_entities)) {
        entity->clearConnection();
    }

    if (m_rosNode) {
        try {
            auto executor = QRos2Context::instance().executor();
            if (executor) {
                executor->remove_node(m_rosNode);
            }
        } catch (const std::exception&) {
        }

        m_rosNode.reset();
    }

    if (m_initialized) {
        m_initialized = false;
        emit initializedChanged();
    }
}

void QRos2Node::updateAllConnectionStates()
{
    for (auto entity : std::as_const(m_entities)) {
        entity->checkHealth();
    }
}

QQmlListProperty<QRos2Entity> QRos2Node::childEntities()
{
    return QQmlListProperty<QRos2Entity>(this,
                                         nullptr,
                                         &QRos2Node::appendChildEntity,
                                         &QRos2Node::childEntitiesCount,
                                         &QRos2Node::childEntityAt,
                                         &QRos2Node::clearChildEntities);
}

void QRos2Node::appendChildEntity(QQmlListProperty<QRos2Entity> *list, QRos2Entity *entity)
{
    QRos2Node* node = qobject_cast<QRos2Node*>(list->object);
    if (node && entity) {
        qCInfo(lcNode) << node << entity;
        node->m_children.append(entity);
        entity->setNode(node);
    }
}

qsizetype QRos2Node::childEntitiesCount(QQmlListProperty<QRos2Entity> *list)
{
    QRos2Node* node = qobject_cast<QRos2Node*>(list->object);

    return node ? node->m_children.count() : 0;
}

QRos2Entity *QRos2Node::childEntityAt(QQmlListProperty<QRos2Entity> *list, qsizetype index)
{
    QRos2Node* node = qobject_cast<QRos2Node*>(list->object);
    return (node && index >= 0 && index < node->m_children.count()) ? node->m_children.at(index)
                                                                    : nullptr;
}

void QRos2Node::clearChildEntities(QQmlListProperty<QRos2Entity> *list)
{
    QRos2Node* node = qobject_cast<QRos2Node*>(list->object);
    if (node) {
        node->m_children.clear();
    }
}

void QRos2Node::registerEntity(QRos2Entity* entity)
{
    if (!entity || m_entities.contains(entity)) return;

    qCInfo(lcNode) << entity << "set up connection?" << (m_initialized && m_rosNode);

    m_entities.append(entity);

    if (m_initialized && m_rosNode) {
        entity->setupConnection();
    }

    emit entitiesChanged();
    
}

void QRos2Node::unregisterEntity(QRos2Entity* entity)
{
    qCInfo(lcNode) << "removing" << entity;
    m_entities.removeOne(entity);

    emit entitiesChanged();
}

void QRos2Node::classBegin()
{

}

QT_END_NAMESPACE
