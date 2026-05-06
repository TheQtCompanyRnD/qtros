// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef QROS2NODE_P_H
#define QROS2NODE_P_H

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
#include <QObject>
#include <QString>
#include <QTimer>
#include <QQmlEngine>
#include <QQmlListProperty>
#include <QQmlParserStatus>
#ifndef Q_QDOC
#include <rclcpp/rclcpp.hpp>
#endif

QT_BEGIN_NAMESPACE

class QRos2Entity;

class Q_ROS2CORE_EXPORT QRos2Node : public QObject, public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)
    QML_NAMED_ELEMENT(Node)
    Q_CLASSINFO("DefaultProperty", "childEntities")

    Q_PROPERTY(QString nodeName READ nodeName WRITE setNodeName NOTIFY nodeNameChanged)
    Q_PROPERTY(QString nodeNamespace READ nodeNamespace WRITE setNodeNamespace NOTIFY nodeNamespaceChanged)
    Q_PROPERTY(bool initialized READ initialized NOTIFY initializedChanged)
    Q_PROPERTY(QList<QRos2Entity*> entities READ entities NOTIFY entitiesChanged)
    Q_PROPERTY(QQmlListProperty<QRos2Entity> childEntities READ childEntities)

public:
    explicit QRos2Node(QObject* parent = nullptr);
    ~QRos2Node() override;

    QString nodeName() const { return m_nodeName; }
    void setNodeName(const QString& name);

    QString nodeNamespace() const { return m_nodeNamespace; }
    void setNodeNamespace(const QString& ns);

    QList<QRos2Entity*> entities() const { return m_entities;}

    bool initialized() const { return m_initialized; }

#ifndef Q_QDOC
    rclcpp::Node::SharedPtr rosNode() const { return m_rosNode; }
#endif

    QQmlListProperty<QRos2Entity> childEntities();

    void registerEntity(QRos2Entity* entity);
    void unregisterEntity(QRos2Entity* entity);

    void classBegin() override;
    void componentComplete() override;

Q_SIGNALS:
    void nodeNameChanged();
    void nodeNamespaceChanged();
    void initializedChanged();
    void entitiesChanged();

private Q_SLOTS:
    void updateAllConnectionStates();

private:
    void initializeNode();
    void shutdownNode();

    static void appendChildEntity(QQmlListProperty<QRos2Entity> *list, QRos2Entity *entity);
    static qsizetype childEntitiesCount(QQmlListProperty<QRos2Entity> *list);
    static QRos2Entity *childEntityAt(QQmlListProperty<QRos2Entity> *list, qsizetype index);
    static void clearChildEntities(QQmlListProperty<QRos2Entity> *list);

    QString m_nodeName;
    QString m_nodeNamespace;
    bool m_initialized = false;
    bool m_componentComplete = false;

#ifndef Q_QDOC
    rclcpp::Node::SharedPtr m_rosNode;
#endif
    QTimer m_healthTimer;

    QList<QRos2Entity *> m_children;
    QList<QRos2Entity*> m_entities;
};

QT_END_NAMESPACE

#endif // QROS2NODE_P_H
