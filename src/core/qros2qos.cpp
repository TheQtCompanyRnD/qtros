// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2qos_p.h"

QT_BEGIN_NAMESPACE

QRos2QoS::QRos2QoS(int queueSize)
    : m_queueSize(queueSize)
{
}

QRos2QoS::operator rclcpp::QoS() const
{
    rclcpp::QoS qos(m_queueSize);

    switch (m_reliability) {
    case RMW_QOS_POLICY_RELIABILITY_RELIABLE:
        qos.reliable();
        break;
    case RMW_QOS_POLICY_RELIABILITY_BEST_EFFORT:
        qos.best_effort();
        break;
    case RMW_QOS_POLICY_RELIABILITY_BEST_AVAILABLE:
        // rclcpp doesn't have a direct method for best_available,
        // use reliability() with the RMW constant
        qos.reliability(static_cast<rmw_qos_reliability_policy_t>(m_reliability));
        break;
    case RMW_QOS_POLICY_RELIABILITY_UNKNOWN:
        qos.reliability(static_cast<rmw_qos_reliability_policy_t>(m_reliability));
        break;
    case RMW_QOS_POLICY_RELIABILITY_SYSTEM_DEFAULT:
        break;
    }

    switch (m_durability) {
    case RMW_QOS_POLICY_DURABILITY_TRANSIENT_LOCAL:
        qos.transient_local();
        break;
    case RMW_QOS_POLICY_DURABILITY_VOLATILE:
        qos.durability_volatile();
        break;
    case RMW_QOS_POLICY_DURABILITY_BEST_AVAILABLE:
        // Use durability() with the RMW constant
        qos.durability(static_cast<rmw_qos_durability_policy_t>(m_durability));
        break;
    case RMW_QOS_POLICY_DURABILITY_UNKNOWN:
        qos.durability(static_cast<rmw_qos_durability_policy_t>(m_durability));
        break;
    case RMW_QOS_POLICY_DURABILITY_SYSTEM_DEFAULT:
        break;
    }

    switch (m_history) {
    case RMW_QOS_POLICY_HISTORY_KEEP_LAST:
        qos.keep_last(m_queueSize);
        break;
    case RMW_QOS_POLICY_HISTORY_KEEP_ALL:
        qos.keep_all();
        break;
    case RMW_QOS_POLICY_HISTORY_UNKNOWN:
        qos.history(static_cast<rmw_qos_history_policy_t>(m_history));
        break;
    case RMW_QOS_POLICY_HISTORY_SYSTEM_DEFAULT:
        break;
    }

    switch (m_liveliness) {
    case RMW_QOS_POLICY_LIVELINESS_AUTOMATIC:
        qos.liveliness(RMW_QOS_POLICY_LIVELINESS_AUTOMATIC);
        break;
    case RMW_QOS_POLICY_LIVELINESS_MANUAL_BY_NODE:
        qos.liveliness(RMW_QOS_POLICY_LIVELINESS_MANUAL_BY_NODE);
        break;
    case RMW_QOS_POLICY_LIVELINESS_MANUAL_BY_TOPIC:
        qos.liveliness(RMW_QOS_POLICY_LIVELINESS_MANUAL_BY_TOPIC);
        break;
    case RMW_QOS_POLICY_LIVELINESS_UNKNOWN:
        qos.liveliness(static_cast<rmw_qos_liveliness_policy_t>(m_liveliness));
        break;
    case RMW_QOS_POLICY_LIVELINESS_SYSTEM_DEFAULT:
        break;
    }

    return qos;
}

QT_END_NAMESPACE
