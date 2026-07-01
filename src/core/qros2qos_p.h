// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef QROS2_QOS_P_H
#define QROS2_QOS_P_H

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
#ifndef Q_QDOC
#include <rclcpp/qos.hpp>
#include <rmw/types.h>
#endif
#include <QQmlEngine>

QT_BEGIN_NAMESPACE

/**
 * @brief Qt wrapper for ROS 2 QoS settings
 *
 * This Q_GADGET provides a Qt-friendly interface to ROS 2 Quality of Service settings.
 * It can be used in QML and has implicit conversion to rclcpp::QoS.
 */
class Q_ROS2CORE_EXPORT QRos2QoS
{
    Q_GADGET
    QML_VALUE_TYPE(qualityOfService)
    QML_STRUCTURED_VALUE

    Q_PROPERTY(int queueSize READ queueSize WRITE setQueueSize)
    Q_PROPERTY(int reliability READ reliability WRITE setReliability)
    Q_PROPERTY(int durability READ durability WRITE setDurability)
    Q_PROPERTY(int history READ history WRITE setHistory)
    Q_PROPERTY(int liveliness READ liveliness WRITE setLiveliness)

public:
    QRos2QoS() = default;
    explicit QRos2QoS(int queueSize);

    int queueSize() const { return m_queueSize; }
    void setQueueSize(int size) { m_queueSize = size; }

    int reliability() const { return m_reliability; }
    void setReliability(int value) { m_reliability = value; }

    int durability() const { return m_durability; }
    void setDurability(int value) { m_durability = value; }

    int history() const { return m_history; }
    void setHistory(int value) { m_history = value; }

    int liveliness() const { return m_liveliness; }
    void setLiveliness(int value) { m_liveliness = value; }

#ifndef Q_QDOC
    operator rclcpp::QoS() const;
#endif


private:
    int m_queueSize = 10;
#ifndef Q_QDOC
    int m_reliability = RMW_QOS_POLICY_RELIABILITY_SYSTEM_DEFAULT;
    int m_durability = RMW_QOS_POLICY_DURABILITY_SYSTEM_DEFAULT;
    int m_history = RMW_QOS_POLICY_HISTORY_SYSTEM_DEFAULT;
    int m_liveliness = RMW_QOS_POLICY_LIVELINESS_SYSTEM_DEFAULT;
#else
    int m_reliability = 0, m_durability = 0, m_history = 0, m_liveliness = 0;
#endif
};

/**
 * @brief QML factory + enum namespace for QoS.
 *
 * A QML singleton companion to the qualityOfService value type (mirrors the
 * Quaternion/quaternion pattern). It hosts the QoS policy enums and a set of
 * ready-made profiles, so QML can write e.g.
 *   qos: QualityOfService.sensorData()
 *   qos.durability: QualityOfService.DurabilityTransientLocal
 * without reaching the enums through an unrelated publisher/subscriber type.
 */
class Q_ROS2CORE_EXPORT QRos2QualityOfService : public QObject
{
    Q_OBJECT
    QML_NAMED_ELEMENT(QualityOfService)
    QML_SINGLETON

public:
    explicit QRos2QualityOfService(QObject* parent = nullptr) : QObject(parent) {}

    enum class ReliabilityPolicy {
#ifndef Q_QDOC
        ReliabilitySystemDefault = RMW_QOS_POLICY_RELIABILITY_SYSTEM_DEFAULT,
        ReliabilityReliable = RMW_QOS_POLICY_RELIABILITY_RELIABLE,
        ReliabilityBestEffort = RMW_QOS_POLICY_RELIABILITY_BEST_EFFORT,
        ReliabilityUnknown = RMW_QOS_POLICY_RELIABILITY_UNKNOWN,
        ReliabilityBestAvailable = RMW_QOS_POLICY_RELIABILITY_BEST_AVAILABLE
#else
        ReliabilitySystemDefault, ReliabilityReliable, ReliabilityBestEffort,
        ReliabilityUnknown, ReliabilityBestAvailable
#endif
    };
    Q_ENUM(ReliabilityPolicy)

    enum class DurabilityPolicy {
#ifndef Q_QDOC
        DurabilitySystemDefault = RMW_QOS_POLICY_DURABILITY_SYSTEM_DEFAULT,
        DurabilityTransientLocal = RMW_QOS_POLICY_DURABILITY_TRANSIENT_LOCAL,
        DurabilityVolatile = RMW_QOS_POLICY_DURABILITY_VOLATILE,
        DurabilityUnknown = RMW_QOS_POLICY_DURABILITY_UNKNOWN,
        DurabilityBestAvailable = RMW_QOS_POLICY_DURABILITY_BEST_AVAILABLE
#else
        DurabilitySystemDefault, DurabilityTransientLocal, DurabilityVolatile,
        DurabilityUnknown, DurabilityBestAvailable
#endif
    };
    Q_ENUM(DurabilityPolicy)

    enum class HistoryPolicy {
#ifndef Q_QDOC
        HistorySystemDefault = RMW_QOS_POLICY_HISTORY_SYSTEM_DEFAULT,
        HistoryKeepLast = RMW_QOS_POLICY_HISTORY_KEEP_LAST,
        HistoryKeepAll = RMW_QOS_POLICY_HISTORY_KEEP_ALL,
        HistoryUnknown = RMW_QOS_POLICY_HISTORY_UNKNOWN
#else
        HistorySystemDefault, HistoryKeepLast, HistoryKeepAll, HistoryUnknown
#endif
    };
    Q_ENUM(HistoryPolicy)

    enum class LivelinessPolicy {
#ifndef Q_QDOC
        LivelinessSystemDefault = RMW_QOS_POLICY_LIVELINESS_SYSTEM_DEFAULT,
        LivelinessAutomatic = RMW_QOS_POLICY_LIVELINESS_AUTOMATIC,
        LivelinessManualByNode = 2,
        LivelinessManualByTopic = RMW_QOS_POLICY_LIVELINESS_MANUAL_BY_TOPIC,
        LivelinessUnknown = RMW_QOS_POLICY_LIVELINESS_UNKNOWN
#else
        LivelinessSystemDefault, LivelinessAutomatic, LivelinessManualByNode,
        LivelinessManualByTopic, LivelinessUnknown
#endif
    };
    Q_ENUM(LivelinessPolicy)

    // Ready-made profiles mirroring the rmw QoS profiles.
    Q_INVOKABLE static QRos2QoS systemDefault();
    Q_INVOKABLE static QRos2QoS sensorData();
    Q_INVOKABLE static QRos2QoS servicesDefault();
    Q_INVOKABLE static QRos2QoS parametersDefault();
    // Reliable + transient-local (latched): the right default for one-shot
    // latched topics such as maps and /tf_static.
    Q_INVOKABLE static QRos2QoS transientLocal();
};

QT_END_NAMESPACE

Q_DECLARE_METATYPE(QRos2QoS)

#endif // QROS2_QOS_P_H
