// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2frametransformer_p.h"
#include <QtRos2Core/private/qros2node_p.h>

#include <QLoggingCategory>
#ifndef Q_QDOC
#include <tf2/time.hpp>
#include <tf2/exceptions.hpp>
#endif

QT_BEGIN_NAMESPACE

Q_LOGGING_CATEGORY(lcFrameTransformer, "qt.robotics.transforms")

/*!
    \qmltype FrameTransformer
    \inqmlmodule QtRos2.Transforms
    \inherits Entity
    \brief Looks up coordinate-frame transforms from the TF tree.

    FrameTransformer is the receive side of \l {QtRos2.Transforms}. Place it as a
    child of a \l Node; it subscribes to \c /tf and \c /tf_static and maintains a
    \c tf2_ros::Buffer behind the scenes. Ask it for the transform between any two
    connected frames with \l lookupTransform — the multi-hop path, the time
    history, and the interpolation are handled for you.

    \qml
    FrameTransformer { id: tf }
    // ... later, e.g. to place the laser in the map frame:
    property var t: tf.canTransform("map", "laser_frame")
                        ? tf.lookupTransform("map", "laser_frame") : null
    \endqml

    Bindings that call \l lookupTransform re-evaluate on \l transformsChanged,
    which fires whenever new transforms arrive.

    \sa TransformBroadcaster, StaticTransformBroadcaster
*/

QRos2FrameTransformer::QRos2FrameTransformer(QObject* parent)
    : QRos2Entity(parent)
{
}

void QRos2FrameTransformer::setupConnection()
{
    clearConnection();

    if (!node() || !node()->rosNode())
        return;

    auto rosNode = node()->rosNode();
    m_buffer = std::make_shared<tf2_ros::Buffer>(rosNode->get_clock());

    // /tf: dynamic transforms, default depth-100 volatile (matches tf2_ros).
    m_tfSub = rosNode->create_subscription<tf2_msgs::msg::TFMessage>(
        "/tf", rclcpp::QoS(100),
        [this](tf2_msgs::msg::TFMessage::SharedPtr msg) { ingest(*msg, false); });

    // /tf_static: latched, so we must request transient-local to receive transforms
    // broadcast before we subscribed.
    rclcpp::QoS staticQos(100);
    staticQos.transient_local();
    m_tfStaticSub = rosNode->create_subscription<tf2_msgs::msg::TFMessage>(
        "/tf_static", staticQos,
        [this](tf2_msgs::msg::TFMessage::SharedPtr msg) { ingest(*msg, true); });
}

void QRos2FrameTransformer::clearConnection()
{
    m_tfSub.reset();
    m_tfStaticSub.reset();
    m_buffer.reset();
}

void QRos2FrameTransformer::ingest(const tf2_msgs::msg::TFMessage& msg, bool isStatic)
{
    if (!m_buffer)
        return;
    for (const auto& t : msg.transforms) {
        try {
            m_buffer->setTransform(t, "qtros2_frametransformer", isStatic);
        } catch (const tf2::TransformException& ex) {
            qCWarning(lcFrameTransformer) << "rejected transform:" << ex.what();
        }
    }
    // Subscription callbacks may run on an executor thread; marshal the signal
    // to this object's thread so QML bindings re-evaluate safely.
    QMetaObject::invokeMethod(this, &QRos2FrameTransformer::transformsChanged,
                              Qt::QueuedConnection);
}

/*!
    \qmlmethod transformStamped FrameTransformer::lookupTransform(string targetFrame, string sourceFrame)

    Returns the latest transform that expresses data in \a sourceFrame in the
    \a targetFrame. On failure (frames not connected yet, or not connected to a
    \l Node) returns a default-constructed value with an empty \c childFrameId and
    logs a warning; call \l canTransform first if you need to branch.
*/
Qtros2GeometryMsgs::TransformStamped QRos2FrameTransformer::lookupTransform(
    const QString& targetFrame, const QString& sourceFrame) const
{
    if (!m_buffer)
        return {};
    try {
        return Qtros2GeometryMsgs::TransformStamped(m_buffer->lookupTransform(
            targetFrame.toStdString(), sourceFrame.toStdString(), tf2::TimePointZero));
    } catch (const tf2::TransformException& ex) {
        qCWarning(lcFrameTransformer) << "lookupTransform" << targetFrame << "<-"
                                      << sourceFrame << "failed:" << ex.what();
        return {};
    }
}

/*!
    \qmlmethod bool FrameTransformer::canTransform(string targetFrame, string sourceFrame)

    Returns \c true if the latest \a sourceFrame to \a targetFrame transform is
    currently resolvable from the TF tree.
*/
bool QRos2FrameTransformer::canTransform(
    const QString& targetFrame, const QString& sourceFrame) const
{
    if (!m_buffer)
        return false;
    return m_buffer->canTransform(targetFrame.toStdString(), sourceFrame.toStdString(),
                                  tf2::TimePointZero);
}

QT_END_NAMESPACE
