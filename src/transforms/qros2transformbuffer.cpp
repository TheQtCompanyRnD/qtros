// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2transformbuffer_p.h"
#include <QtRos2Core/private/qros2node_p.h>

#include <QLoggingCategory>
#ifndef Q_QDOC
#include <tf2/time.hpp>
#include <tf2/exceptions.hpp>
#endif

QT_BEGIN_NAMESPACE

Q_STATIC_LOGGING_CATEGORY(lcTransformBuffer, "qt.robotics.transforms")

QRos2TransformBuffer *QRos2TransformBuffer::forNode(QRos2Node *node)
{
    if (!node)
        return nullptr;
    if (auto *buffer = node->findChild<QRos2TransformBuffer *>(Qt::FindDirectChildrenOnly))
        return buffer;
    return new QRos2TransformBuffer(node);
}

QRos2TransformBuffer::QRos2TransformBuffer(QRos2Node *node)
    : QObject(node)
{
    connect(node, &QRos2Node::initializedChanged, this, [this, node] {
        if (node->initialized())
            setupConnection();
        else
            clearConnection();
    });
    setupConnection();
}

QRos2TransformBuffer::~QRos2TransformBuffer()
{
    clearConnection();
}

QRos2Node *QRos2TransformBuffer::node() const
{
    return static_cast<QRos2Node *>(parent());
}

void QRos2TransformBuffer::setupConnection()
{
    clearConnection();

    auto rosNode = node()->rosNode();
    if (!rosNode)
        return;

    // The callbacks run on the executor thread. Each captures the buffer it
    // fills, so that clearConnection() resetting m_buffer on this thread doesn't
    // race with a callback in flight. tf2_ros::Buffer is itself thread-safe.
    m_buffer = std::make_shared<tf2_ros::Buffer>(rosNode->get_clock());

    // Node remaps /tf and /tf_static to the relative tf and tf_static, so
    // these resolve under the node's namespace.
    // /tf: dynamic transforms, default depth-100 volatile (matches tf2_ros).
    m_tfSub = rosNode->create_subscription<tf2_msgs::msg::TFMessage>(
        "/tf", rclcpp::QoS(100),
        [this, buffer = m_buffer](tf2_msgs::msg::TFMessage::SharedPtr msg) {
            ingest(*buffer, *msg, false);
        });

    // /tf_static: latched, so we must request transient-local to receive transforms
    // broadcast before we subscribed.
    rclcpp::QoS staticQos(100);
    staticQos.transient_local();
    m_tfStaticSub = rosNode->create_subscription<tf2_msgs::msg::TFMessage>(
        "/tf_static", staticQos,
        [this, buffer = m_buffer](tf2_msgs::msg::TFMessage::SharedPtr msg) {
            ingest(*buffer, *msg, true);
        });
}

void QRos2TransformBuffer::clearConnection()
{
    m_tfSub.reset();
    m_tfStaticSub.reset();
    m_buffer.reset();
}

void QRos2TransformBuffer::ingest(tf2_ros::Buffer &buffer, const tf2_msgs::msg::TFMessage &msg,
                                  bool isStatic)
{
    for (const auto &t : msg.transforms) {
        try {
            buffer.setTransform(t, "qtros2_transformbuffer", isStatic);
        } catch (const tf2::TransformException &ex) {
            qCWarning(lcTransformBuffer) << "rejected transform:" << ex.what();
        }
    }
    // A robot can publish /tf at hundreds of messages per second, and every
    // FrameNode does a lookup per transformsChanged(); so post at most one
    // notification per event-loop pass, to this object's thread.
    if (!m_notifyPending.exchange(true)) {
        QMetaObject::invokeMethod(this, [this] {
            m_notifyPending = false;
            emit transformsChanged();
        }, Qt::QueuedConnection);
    }
}

bool QRos2TransformBuffer::lookup(const QString &targetFrame, const QString &sourceFrame,
                                  QVector3D *translation, QQuaternion *rotation) const
{
    if (!m_buffer)
        return false;
    const std::string target = targetFrame.toStdString();
    const std::string source = sourceFrame.toStdString();
    try {
        // Passing an error string stops tf2 from logging a warning about each
        // frame that hasn't arrived yet; FrameNode asks on every update.
        std::string error;
        if (!m_buffer->canTransform(target, source, tf2::TimePointZero, &error))
            return false;
        const auto t = m_buffer->lookupTransform(target, source, tf2::TimePointZero).transform;
        if (translation)
            *translation = QVector3D(t.translation.x, t.translation.y, t.translation.z);
        if (rotation)
            *rotation = QQuaternion(t.rotation.w, t.rotation.x, t.rotation.y, t.rotation.z);
        return true;
    } catch (const tf2::TransformException &) {
        return false;
    }
}

Qtros2GeometryMsgs::TransformStamped QRos2TransformBuffer::lookupTransform(
    const QString &targetFrame, const QString &sourceFrame) const
{
    if (!m_buffer)
        return {};
    try {
        return Qtros2GeometryMsgs::TransformStamped(m_buffer->lookupTransform(
            targetFrame.toStdString(), sourceFrame.toStdString(), tf2::TimePointZero));
    } catch (const tf2::TransformException &ex) {
        qCWarning(lcTransformBuffer) << "lookupTransform" << targetFrame << "<-"
                                     << sourceFrame << "failed:" << ex.what();
        return {};
    }
}

bool QRos2TransformBuffer::canTransform(const QString &targetFrame,
                                        const QString &sourceFrame) const
{
    if (!m_buffer)
        return false;
    std::string error; // also keeps tf2 quiet about unknown frames
    return m_buffer->canTransform(targetFrame.toStdString(), sourceFrame.toStdString(),
                                  tf2::TimePointZero, &error);
}

QT_END_NAMESPACE
