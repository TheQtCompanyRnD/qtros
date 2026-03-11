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
#include <rclcpp/qos.hpp>
#include <rmw/types.h>
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
    QML_VALUE_TYPE(ros2_qos)
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

    /**
     * @brief Cast operator for implicit conversion to rclcpp::QoS
     *
     * Converts this Qt QoS object to an rclcpp QoS object that can be used
     * when creating subscriptions and publishers.
     */
    operator rclcpp::QoS() const;


private:
    int m_queueSize = 10;
    int m_reliability = RMW_QOS_POLICY_RELIABILITY_SYSTEM_DEFAULT;
    int m_durability = RMW_QOS_POLICY_DURABILITY_SYSTEM_DEFAULT;
    int m_history = RMW_QOS_POLICY_HISTORY_SYSTEM_DEFAULT;
    int m_liveliness = RMW_QOS_POLICY_LIVELINESS_SYSTEM_DEFAULT;
};

QT_END_NAMESPACE

Q_DECLARE_METATYPE(QRos2QoS)

#endif // QROS2_QOS_P_H
