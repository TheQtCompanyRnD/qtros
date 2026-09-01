// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2remoteparameter_p.h"
#include "qros2node_p.h"
#include "qros2parametervalue_p.h"

#include <QCoreApplication>
#include <QLoggingCategory>
#include <QPointer>

/*!
    \qmltype RemoteParameter
    \inqmlmodule QtRos2.Core
    \inherits NodeChild
    \brief Binds to a parameter of another ROS 2 node as desired state.

    RemoteParameter is the client side of \l Parameter (or of any ROS 2
    node's parameter): \l value expresses the desired value, \l reported
    tracks what the remote node actually holds.

    \qml
    Node {
        nodeName: "twin"
        RemoteParameter {
            id: masterVolume
            remoteNode: "/dogzilla/dogzilla"
            name: "audio.master"
            value: volumeSlider.value
        }
    }
    // display: text: `${Math.round(masterVolume.reported * 100)}%`
    \endqml

    Writing (or binding) \l value schedules a coalesced set of the
    remote parameter: multiple changes per event-loop iteration collapse
    into one request, changes made while the remote node is unavailable
    or a request is in flight are remembered, and the latest value is
    applied as soon as possible — the binding behaves like desired state
    that is reconciled with the remote node. A set the remote rejects
    (range violation, unknown parameter, read-only) emits \l setFailed
    and is not retried.

    \l reported holds the remote node's actual value: fetched once when
    the remote parameter services become \l ready, then tracked via the
    global \c /parameter_events topic. It is \c undefined while unknown
    and after the remote parameter is deleted.
*/

/*!
    \qmlproperty string RemoteParameter::remoteNode

    The fully-qualified name of the remote node (e.g.
    \c {"/dogzilla/dogzilla"}). A relative name is resolved against the
    local node's namespace.
*/

/*!
    \qmlproperty string RemoteParameter::name

    The parameter name on the remote node.
*/

/*!
    \qmlproperty var RemoteParameter::value

    The desired parameter value. When \l autoApply is \c true (the
    default), each change schedules a coalesced set request;
    latest-wins reconciliation applies it as soon as the remote node is
    reachable and no other request is in flight.
*/

/*!
    \qmlproperty var RemoteParameter::reported

    Read-only: the value the remote node actually holds — initial fetch
    plus updates from \c /parameter_events. \c undefined while unknown.
*/

/*!
    \qmlproperty bool RemoteParameter::ready

    Read-only: \c true while the remote node's parameter services are
    available on the graph.
*/

/*!
    \qmlproperty bool RemoteParameter::pending

    Read-only: \c true while a set request is in flight.
*/

/*!
    \qmlproperty bool RemoteParameter::autoApply

    If \c true (the default), changes of \l value are applied
    automatically. If \c false, writes only store the value; call
    \l apply() explicitly, or enable \c autoApply to dispatch the most
    recent stored value — gating \c autoApply gates dispatch, not
    intent.
*/

/*!
    \qmlmethod void RemoteParameter::apply()

    Sends the current \l value to the remote node, regardless of
    \l autoApply (still deferred until \l ready if the remote is
    unavailable).
*/

/*!
    \qmlmethod void RemoteParameter::refresh()

    Re-fetches \l reported from the remote node.
*/

/*!
    \qmlsignal RemoteParameter::setFailed(string reason)

    Emitted when the remote node rejected a set request or it could not
    be delivered; \a reason describes why (range violation, undeclared
    parameter, read-only). The rejected value is not retried.
*/

QT_BEGIN_NAMESPACE

Q_STATIC_LOGGING_CATEGORY(lcRemoteParam, "qt.robotics.parameter")

using namespace QRos2ParameterValueHelpers;

QRos2RemoteParameter::QRos2RemoteParameter(QObject* parent)
    : QRos2NodeChild(parent)
{
}

QRos2RemoteParameter::~QRos2RemoteParameter() = default;

QString QRos2RemoteParameter::resolvedRemoteNode() const
{
    if (m_remoteNode.isEmpty() || m_remoteNode.startsWith(QLatin1Char('/')))
        return m_remoteNode;
    QString ns;
    if (m_node && m_node->rosNode())
        ns = QString::fromStdString(m_node->rosNode()->get_namespace());
    if (!ns.endsWith(QLatin1Char('/')))
        ns += QLatin1Char('/');
    return ns + m_remoteNode;
}

void QRos2RemoteParameter::setRemoteNode(const QString& remoteNode)
{
    if (m_remoteNode == remoteNode) return;
    m_remoteNode = remoteNode;
    emit remoteNodeChanged();
    reconnect();
}

void QRos2RemoteParameter::setName(const QString& name)
{
    if (m_name == name) return;
    m_name = name;
    emit nameChanged();
    reconnect();
}

void QRos2RemoteParameter::reconnect()
{
    clearConnection();
    if (m_value.isValid())
        m_dirty = true;   // desired state carries over to the new target
    setupConnection();
}

void QRos2RemoteParameter::setValue(const QVariant& value)
{
    if (m_value == value) return;
    m_value = value;
    emit valueChanged();

    // Remember the write even while autoApply is off: enabling autoApply
    // (or calling apply()) dispatches the latest stored value.
    m_dirty = true;
    if (m_autoApply)
        scheduleApplyAttempt();
}

void QRos2RemoteParameter::setAutoApply(bool autoApply)
{
    if (m_autoApply == autoApply) return;
    m_autoApply = autoApply;
    emit autoApplyChanged();
    if (autoApply)
        scheduleApplyAttempt();
}

void QRos2RemoteParameter::apply()
{
    m_dirty = true;
    attemptApply(/*force=*/true);
}

void QRos2RemoteParameter::refresh()
{
    if (!m_client || !m_ready || m_name.isEmpty())
        return;
    auto weakThis = QPointer<QRos2RemoteParameter>(this);
    m_client->get_parameters(
        {m_name.toStdString()},
        [weakThis](std::shared_future<std::vector<rclcpp::Parameter>> future) {
            // Executor thread: copy and marshal.
            QVariant v;
            try {
                const auto params = future.get();
                if (!params.empty())
                    v = toVariant(params.front().get_parameter_value());
            } catch (const std::exception&) {
            }
            QMetaObject::invokeMethod(
                qApp,
                [weakThis, v] {
                    if (weakThis)
                        weakThis->updateReported(v);
                },
                Qt::QueuedConnection);
        });
}

void QRos2RemoteParameter::scheduleApplyAttempt()
{
    if (m_attemptScheduled || !m_dirty)
        return;
    m_attemptScheduled = true;
    QMetaObject::invokeMethod(this, [this] {
        m_attemptScheduled = false;
        attemptApply();
    }, Qt::QueuedConnection);
}

void QRos2RemoteParameter::attemptApply(bool force)
{
    if (!m_dirty || (!m_autoApply && !force))
        return;
    // Not ready or busy: keep the dirty flag; checkHealth() and the
    // completion handler re-schedule when the state clears.
    if (!m_ready || m_pending || !m_client)
        return;

    const rclcpp::ParameterType type = m_reported.isValid() ? inferType(m_reported)
                                                            : inferType(m_value);
    const rclcpp::ParameterValue pv = toParameterValue(m_value, type);
    if (pv.get_type() == rclcpp::ParameterType::PARAMETER_NOT_SET) {
        qCWarning(lcRemoteParam) << m_name << "desired value" << m_value
                                 << "is not convertible to a parameter value";
        m_dirty = false;   // don't loop on an unconvertible value
        emit setFailed(QStringLiteral("value not convertible to a parameter value"));
        return;
    }

    m_dirty = false;
    m_pending = true;
    emit pendingChanged();

    auto weakThis = QPointer<QRos2RemoteParameter>(this);
    m_client->set_parameters(
        {rclcpp::Parameter(m_name.toStdString(), pv)},
        [weakThis](std::shared_future<std::vector<rcl_interfaces::msg::SetParametersResult>> future) {
            // Executor thread: copy and marshal.
            bool successful = false;
            QString reason;
            try {
                const auto results = future.get();
                if (!results.empty()) {
                    successful = results.front().successful;
                    reason = QString::fromStdString(results.front().reason);
                } else {
                    reason = QStringLiteral("empty result");
                }
            } catch (const std::exception& e) {
                reason = QString::fromUtf8(e.what());
            }
            QMetaObject::invokeMethod(
                qApp,
                [weakThis, successful, reason] {
                    if (weakThis)
                        weakThis->handleSetResult(successful, reason);
                },
                Qt::QueuedConnection);
        });
}

void QRos2RemoteParameter::handleSetResult(bool successful, const QString& reason)
{
    m_pending = false;
    emit pendingChanged();
    if (!successful) {
        qCWarning(lcRemoteParam) << m_name << "set failed:" << reason;
        emit setFailed(reason);
    }
    // A value stored while the request was in flight goes out now.
    scheduleApplyAttempt();
}

void QRos2RemoteParameter::updateReported(const QVariant& value)
{
    m_reportedFetched = true;
    if (value == m_reported)
        return;
    m_reported = value;
    emit reportedChanged();
}

void QRos2RemoteParameter::setupConnection()
{
    if (!m_node || !m_node->rosNode() || m_remoteNode.isEmpty() || m_name.isEmpty())
        return;

    m_client = std::make_shared<rclcpp::AsyncParametersClient>(
        m_node->rosNode(), resolvedRemoteNode().toStdString());

    // Track the remote value via the global /parameter_events topic
    // (absolute; every node publishes there, events carry the node FQN).
    auto weakThis = QPointer<QRos2RemoteParameter>(this);
    const std::string wantNode = resolvedRemoteNode().toStdString();
    const std::string wantName = m_name.toStdString();
    m_eventSub = m_node->rosNode()->create_subscription<rcl_interfaces::msg::ParameterEvent>(
        QStringLiteral("/parameter_events").toStdString(),
        rclcpp::QoS(rclcpp::QoSInitialization::from_rmw(rmw_qos_profile_parameter_events)),
        [weakThis, wantNode, wantName](const rcl_interfaces::msg::ParameterEvent& event) {
            // Executor thread: filter, copy, marshal.
            if (event.node != wantNode)
                return;
            bool relevant = false;
            QVariant v;
            for (const auto& p : event.new_parameters) {
                if (p.name == wantName) {
                    relevant = true;
                    v = toVariant(rclcpp::ParameterValue(p.value));
                }
            }
            for (const auto& p : event.changed_parameters) {
                if (p.name == wantName) {
                    relevant = true;
                    v = toVariant(rclcpp::ParameterValue(p.value));
                }
            }
            for (const auto& p : event.deleted_parameters) {
                if (p.name == wantName) {
                    relevant = true;
                    v = QVariant();
                }
            }
            if (!relevant)
                return;
            QMetaObject::invokeMethod(
                qApp,
                [weakThis, v] {
                    if (weakThis)
                        weakThis->updateReported(v);
                },
                Qt::QueuedConnection);
        });
}

void QRos2RemoteParameter::clearConnection()
{
    m_eventSub.reset();
    m_client.reset();
    m_reportedFetched = false;
    if (m_pending) {
        m_pending = false;
        emit pendingChanged();
        m_dirty = true;   // in-flight request abandoned; re-apply on reconnect
    }
    if (m_ready) {
        m_ready = false;
        emit readyChanged();
    }
    if (m_reported.isValid()) {
        m_reported = QVariant();
        emit reportedChanged();
    }
}

void QRos2RemoteParameter::checkHealth()
{
    bool ready = false;
    if (m_client) {
        try {
            ready = m_client->service_is_ready();
        } catch (const std::exception&) {
        }
    }
    if (ready == m_ready)
        return;
    m_ready = ready;
    emit readyChanged();
    if (ready) {
        if (!m_reportedFetched)
            refresh();
        scheduleApplyAttempt();
    } else if (m_pending) {
        // Remote vanished mid-flight: the completion may never arrive.
        m_pending = false;
        emit pendingChanged();
        m_dirty = true;
    }
}

QT_END_NAMESPACE
