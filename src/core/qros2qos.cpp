// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2qos_p.h"

QT_BEGIN_NAMESPACE

/*!
    \qmlvaluetype qualityOfService
    \inqmlmodule QtRos2.Core
    \brief ROS 2 Quality of Service settings for a publisher or subscriber.

    Holds the QoS policies (\c reliability, \c durability, \c history,
    \c liveliness and the \c queueSize / depth) applied to an \l Entity's
    \c qos property. Policy values are the enums on \l QualityOfService, e.g.

    \qml
    SomeSubscriber {
        qos.reliability: QualityOfService.ReliabilityBestEffort
        qos.durability: QualityOfService.DurabilityTransientLocal
        qos.queueSize: 5
    }
    \endqml

    For common cases prefer a ready-made profile from \l QualityOfService:
    \c {qos: QualityOfService.sensorData()}.

    \note This is unrelated to \c qoSProfile from \l {QtRos2.RosgraphMsgs},
    which is the \c rosgraph_msgs/QoSProfile introspection message.

    \sa QualityOfService
*/

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

/*!
    \qmltype QualityOfService
    \inqmlmodule QtRos2.Core
    \brief QoS policy enums and ready-made profiles for QML.

    A singleton companion to the \l qualityOfService value type. Use its enums
    to set individual policies (e.g. \c QualityOfService.DurabilityTransientLocal)
    and its factory methods for the standard ROS 2 profiles.

    \sa qualityOfService
*/

/*!
    \qmlmethod qualityOfService QualityOfService::systemDefault()
    The RMW system-default QoS (the default for a freshly-constructed value).
*/
QRos2QoS QRos2QualityOfService::systemDefault()
{
    return QRos2QoS();
}

/*!
    \qmlmethod qualityOfService QualityOfService::sensorData()
    Best-effort, keep-last depth 5, volatile — for high-rate sensor streams
    (scans, images) where the latest sample matters more than delivery.
*/
QRos2QoS QRos2QualityOfService::sensorData()
{
    QRos2QoS qos(5);
    qos.setReliability(RMW_QOS_POLICY_RELIABILITY_BEST_EFFORT);
    qos.setHistory(RMW_QOS_POLICY_HISTORY_KEEP_LAST);
    qos.setDurability(RMW_QOS_POLICY_DURABILITY_VOLATILE);
    return qos;
}

/*!
    \qmlmethod qualityOfService QualityOfService::servicesDefault()
    Reliable, keep-last depth 10, volatile — the default for service exchanges.
*/
QRos2QoS QRos2QualityOfService::servicesDefault()
{
    QRos2QoS qos(10);
    qos.setReliability(RMW_QOS_POLICY_RELIABILITY_RELIABLE);
    qos.setHistory(RMW_QOS_POLICY_HISTORY_KEEP_LAST);
    qos.setDurability(RMW_QOS_POLICY_DURABILITY_VOLATILE);
    return qos;
}

/*!
    \qmlmethod qualityOfService QualityOfService::parametersDefault()
    Reliable, keep-last depth 1000, volatile — matches the parameter services.
*/
QRos2QoS QRos2QualityOfService::parametersDefault()
{
    QRos2QoS qos(1000);
    qos.setReliability(RMW_QOS_POLICY_RELIABILITY_RELIABLE);
    qos.setHistory(RMW_QOS_POLICY_HISTORY_KEEP_LAST);
    qos.setDurability(RMW_QOS_POLICY_DURABILITY_VOLATILE);
    return qos;
}

/*!
    \qmlmethod qualityOfService QualityOfService::transientLocal()
    Reliable + transient-local (latched), keep-last depth 1 — the right default
    for one-shot latched topics such as maps and \c /tf_static, so a late
    subscriber still receives the last value.
*/
QRos2QoS QRos2QualityOfService::transientLocal()
{
    QRos2QoS qos(1);
    qos.setReliability(RMW_QOS_POLICY_RELIABILITY_RELIABLE);
    qos.setHistory(RMW_QOS_POLICY_HISTORY_KEEP_LAST);
    qos.setDurability(RMW_QOS_POLICY_DURABILITY_TRANSIENT_LOCAL);
    return qos;
}

QT_END_NAMESPACE
