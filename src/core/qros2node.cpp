// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2node_p.h"
#include "qros2context.h"
#include "qros2nodechild_p.h"

#include <QDebug>
#include <QLoggingCategory>

/*!
    \qmltype Node
    \inqmlmodule QtRos2.Core
    \brief Represents a ROS 2 node and hosts publisher, subscriber, and
    client entities.

    Node is the primary attachment point for publisher, subscriber,
    service-client, and action-client items. Set the \c node property of
    each entity to this node.

    \qml
    import QtRos2.Core

    Node {
        nodeName: "my_qt_node"
    }
    \endqml

    Child entities declared inside a Node item are automatically
    registered with it via the \c childEntities default property.
*/

/*!
    \qmlproperty string Node::nodeName

    The ROS 2 node name. Must be a valid ROS identifier. Set this before
    the component completes; changing it after initialization has no effect.
*/

/*!
    \qmlproperty string Node::nodeNamespace

    The ROS 2 namespace for this node. Defaults to \c "/" (global namespace).
*/

/*!
    \qmlproperty bool Node::initialized

    Read-only. \c true once the underlying rclcpp node has been created and
    the ROS executor is running. All child entities start their connections
    when this becomes \c true.
*/

/*!
    \qmlproperty list<NodeChild> Node::entities

    Read-only. The list of \l NodeChild items (entities, parameters)
    currently registered with this node. Managed automatically as they
    are created and destroyed.
*/

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
        // tf2 publishes/subscribes on the absolute topics /tf and /tf_static,
        // so without help they would ignore nodeNamespace and every robot would
        // share one global TF tree. Remap them to the relative names tf and
        // tf_static, which then resolve under the node namespace (e.g.
        // /dogzilla/tf). At the root namespace this is a no-op (tf -> /tf). This
        // is the same trick Nav2 uses for multi-robot, applied once here so it
        // covers tf2_ros broadcasters/listeners and QtRos2's own TF entities.
        rclcpp::NodeOptions options;
        options.arguments({
            "--ros-args",
            "-r", "/tf:=tf",
            "-r", "/tf_static:=tf_static",
        });

        m_rosNode = std::make_shared<rclcpp::Node>(
            m_nodeName.toStdString(),
            m_nodeNamespace.toStdString(),
            options
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

QQmlListProperty<QRos2NodeChild> QRos2Node::childEntities()
{
    return QQmlListProperty<QRos2NodeChild>(this,
                                            nullptr,
                                            &QRos2Node::appendChildEntity,
                                            &QRos2Node::childEntitiesCount,
                                            &QRos2Node::childEntityAt,
                                            &QRos2Node::clearChildEntities);
}

void QRos2Node::appendChildEntity(QQmlListProperty<QRos2NodeChild> *list, QRos2NodeChild *entity)
{
    QRos2Node* node = qobject_cast<QRos2Node*>(list->object);
    if (node && entity) {
        qCInfo(lcNode) << node << entity;
        node->m_children.append(entity);
        entity->setNode(node);
    }
}

qsizetype QRos2Node::childEntitiesCount(QQmlListProperty<QRos2NodeChild> *list)
{
    QRos2Node* node = qobject_cast<QRos2Node*>(list->object);

    return node ? node->m_children.count() : 0;
}

QRos2NodeChild *QRos2Node::childEntityAt(QQmlListProperty<QRos2NodeChild> *list, qsizetype index)
{
    QRos2Node* node = qobject_cast<QRos2Node*>(list->object);
    return (node && index >= 0 && index < node->m_children.count()) ? node->m_children.at(index)
                                                                    : nullptr;
}

void QRos2Node::clearChildEntities(QQmlListProperty<QRos2NodeChild> *list)
{
    QRos2Node* node = qobject_cast<QRos2Node*>(list->object);
    if (node) {
        node->m_children.clear();
    }
}

void QRos2Node::registerEntity(QRos2NodeChild* entity)
{
    if (!entity || m_entities.contains(entity)) return;

    qCInfo(lcNode) << entity << "set up connection?" << (m_initialized && m_rosNode);

    m_entities.append(entity);

    if (m_initialized && m_rosNode) {
        entity->setupConnection();
    }

    emit entitiesChanged();
    
}

void QRos2Node::unregisterEntity(QRos2NodeChild* entity)
{
    // When this node is deleting its children (the ~QObject phase), our member
    // m_entities has already been destroyed; a child entity's destructor calling
    // back here must not touch the freed list. QObjectData::isDeletingChildren
    // marks exactly that window. Normal unregistration (node still alive) is
    // unaffected, as the flag is false then.
    if (d_ptr->isDeletingChildren)
        return;

    qCInfo(lcNode) << "removing" << entity;
    m_entities.removeOne(entity);

    emit entitiesChanged();
}

void QRos2Node::classBegin()
{

}

QT_END_NAMESPACE
