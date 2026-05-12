// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef QROS2_ENTITY_P_H
#define QROS2_ENTITY_P_H

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
#include <QQmlEngine>
#include <rmw/types.h>
#include "qros2qos_p.h"

QT_BEGIN_NAMESPACE

class QRos2Node;
Q_MOC_INCLUDE(<QtRos2Core/private/qros2node_p.h>)

class Q_ROS2CORE_EXPORT QRos2Entity : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString topic READ topic WRITE setTopic NOTIFY topicChanged)
    Q_PROPERTY(QRos2Node* node READ node WRITE setNode NOTIFY nodeChanged)
    Q_PROPERTY(QRos2QoS qos READ qos WRITE setQos NOTIFY qosChanged)

    QML_NAMED_ELEMENT(Entity)
    QML_UNCREATABLE("This is just abstract class")

public:
    explicit QRos2Entity(QObject* parent = nullptr);
    ~QRos2Entity() override;

    // QoS enum definitions matching RMW values
    enum class ReliabilityPolicy {
        ReliabilitySystemDefault = RMW_QOS_POLICY_RELIABILITY_SYSTEM_DEFAULT,
        ReliabilityReliable = RMW_QOS_POLICY_RELIABILITY_RELIABLE,
        ReliabilityBestEffort = RMW_QOS_POLICY_RELIABILITY_BEST_EFFORT,
        ReliabilityUnknown = RMW_QOS_POLICY_RELIABILITY_UNKNOWN,
        ReliabilityBestAvailable = RMW_QOS_POLICY_RELIABILITY_BEST_AVAILABLE
    };
    Q_ENUM(ReliabilityPolicy)

    enum class DurabilityPolicy {
        DurabilitySystemDefault = RMW_QOS_POLICY_DURABILITY_SYSTEM_DEFAULT,
        DurabilityTransientLocal = RMW_QOS_POLICY_DURABILITY_TRANSIENT_LOCAL,
        DurabilityVolatile = RMW_QOS_POLICY_DURABILITY_VOLATILE,
        DurabilityUnknown = RMW_QOS_POLICY_DURABILITY_UNKNOWN,
        DurabilityBestAvailable = RMW_QOS_POLICY_DURABILITY_BEST_AVAILABLE
    };
    Q_ENUM(DurabilityPolicy)

    enum class HistoryPolicy {
        HistorySystemDefault = RMW_QOS_POLICY_HISTORY_SYSTEM_DEFAULT,
        HistoryKeepLast = RMW_QOS_POLICY_HISTORY_KEEP_LAST,
        HistoryKeepAll = RMW_QOS_POLICY_HISTORY_KEEP_ALL,
        HistoryUnknown = RMW_QOS_POLICY_HISTORY_UNKNOWN
    };
    Q_ENUM(HistoryPolicy)

    enum class LivelinessPolicy {
        LivelinessSystemDefault = RMW_QOS_POLICY_LIVELINESS_SYSTEM_DEFAULT,
        LivelinessAutomatic = RMW_QOS_POLICY_LIVELINESS_AUTOMATIC,
        LivelinessManualByNode = 2, //actually RMW_QOS_POLICY_LIVELINESS_MANUAL_BY_NODE - but causes a lot of spam because of depreciation warning,
        LivelinessManualByTopic = RMW_QOS_POLICY_LIVELINESS_MANUAL_BY_TOPIC,
        LivelinessUnknown = RMW_QOS_POLICY_LIVELINESS_UNKNOWN
    };
    Q_ENUM(LivelinessPolicy)

    QString topic() const { return m_topic; }
    void setTopic(const QString& topic);

    QRos2Node* node() const { return m_node; }
    void setNode(QRos2Node* node);

    QRos2QoS qos() const { return m_qos; }
    void setQos(const QRos2QoS& qos);

    // Called when parent node is initialized to setup the ROS2 connection
    virtual void setupConnection() = 0;
    virtual void clearConnection() = 0;

    // Called periodically by QRos2Node to update connection state
    virtual void checkHealth() {}

Q_SIGNALS:
    void topicChanged();
    void nodeChanged();
    void qosChanged();

protected:
    QString m_topic;
    QRos2Node* m_node = nullptr;
    QRos2QoS m_qos;

    friend class QRos2Node;
};

QT_END_NAMESPACE

#endif // QROS2_ENTITY_P_H
