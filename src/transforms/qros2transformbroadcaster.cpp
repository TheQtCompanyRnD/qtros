// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2transformbroadcaster_p.h"
#include <QtRos2Core/private/qros2node_p.h>

#include <vector>

QT_BEGIN_NAMESPACE

/*!
    \qmltype TransformBroadcaster
    \inqmlmodule QtRos2.Transforms
    \inherits Entity
    \brief Publishes dynamic coordinate-frame transforms on \c /tf.

    TransformBroadcaster wraps \c tf2_ros::TransformBroadcaster. Place it as a
    child of a \l Node and call \l sendTransform with a \c transformStamped
    each time a frame moves (e.g. an odometry update). The transform's
    \c header.frameId is the parent frame, \c childFrameId the child, and
    \c header.stamp the time the transform is valid for.

    For transforms that never change, use \l StaticTransformBroadcaster
    instead — it publishes once on the latched \c /tf_static topic.

    \sa StaticTransformBroadcaster, FrameTransformer
*/

QRos2TransformBroadcaster::QRos2TransformBroadcaster(QObject* parent)
    : QRos2Entity(parent)
{
}

void QRos2TransformBroadcaster::setupConnection()
{
    m_broadcaster.reset();

    if (!node() || !node()->rosNode())
        return;

    m_broadcaster = std::make_shared<tf2_ros::TransformBroadcaster>(node()->rosNode());
}

void QRos2TransformBroadcaster::clearConnection()
{
    m_broadcaster.reset();
}

/*!
    \qmlmethod void TransformBroadcaster::sendTransform(transformStamped transform)

    Broadcasts a single \a transform on \c /tf. Does nothing if the broadcaster
    is not yet connected to a \l Node.
*/
void QRos2TransformBroadcaster::sendTransform(const Qtros2GeometryMsgs::TransformStamped& transform)
{
    if (!m_broadcaster)
        return;
    m_broadcaster->sendTransform(static_cast<geometry_msgs::msg::TransformStamped>(transform));
}

/*!
    \qmlmethod void TransformBroadcaster::sendTransforms(list<transformStamped> transforms)

    Broadcasts several \a transforms on \c /tf in a single message.
*/
void QRos2TransformBroadcaster::sendTransforms(const QList<Qtros2GeometryMsgs::TransformStamped>& transforms)
{
    if (!m_broadcaster)
        return;
    std::vector<geometry_msgs::msg::TransformStamped> ros;
    ros.reserve(transforms.size());
    for (const auto& t : transforms)
        ros.push_back(static_cast<geometry_msgs::msg::TransformStamped>(t));
    m_broadcaster->sendTransform(ros);
}

QT_END_NAMESPACE
