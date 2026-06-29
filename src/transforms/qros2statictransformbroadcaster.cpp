// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2statictransformbroadcaster_p.h"
#include <QtRos2Core/private/qros2node_p.h>

#include <vector>

QT_BEGIN_NAMESPACE

/*!
    \qmltype StaticTransformBroadcaster
    \inqmlmodule QtRos2.Transforms
    \inherits Entity
    \brief Publishes fixed coordinate-frame transforms on the latched \c /tf_static.

    StaticTransformBroadcaster wraps \c tf2_ros::StaticTransformBroadcaster. Use
    it for transforms that do not change at runtime — typically sensor mounting
    offsets read from a URDF (e.g. \c base_link to \c laser_frame).

    Unlike \l TransformBroadcaster, you call \l sendTransform once. The message
    is published with transient-local (latched) durability on \c /tf_static, so
    a \l FrameTransformer (or any tf2 listener) that starts \e after the
    broadcaster still receives it. Successive calls accumulate: each call
    republishes all previously sent static transforms plus the new ones.

    \sa TransformBroadcaster, FrameTransformer
*/

QRos2StaticTransformBroadcaster::QRos2StaticTransformBroadcaster(QObject* parent)
    : QRos2Entity(parent)
{
}

/*!
    \qmlproperty list<transformStamped> StaticTransformBroadcaster::transforms

    The static transforms to latch on \c /tf_static. Assigning this property
    publishes them immediately if the broadcaster is connected to a \l Node, and
    they are also (re)published automatically whenever the node connection is
    (re)established. This is the declarative way to publish fixed transforms — no
    need to call \l sendTransform from \c Component.onCompleted, which would race
    with node initialization.
*/
void QRos2StaticTransformBroadcaster::setTransforms(const QList<Qtros2GeometryMsgs::TransformStamped>& transforms)
{
    m_transforms = transforms;
    emit transformsChanged();
    if (m_broadcaster && !m_transforms.isEmpty())
        sendTransforms(m_transforms);
}

void QRos2StaticTransformBroadcaster::setupConnection()
{
    m_broadcaster.reset();

    if (!node() || !node()->rosNode())
        return;

    m_broadcaster = std::make_shared<tf2_ros::StaticTransformBroadcaster>(node()->rosNode());

    // (Re)latch any declaratively-configured transforms now that the node is up.
    if (!m_transforms.isEmpty())
        sendTransforms(m_transforms);
}

void QRos2StaticTransformBroadcaster::clearConnection()
{
    m_broadcaster.reset();
}

/*!
    \qmlmethod void StaticTransformBroadcaster::sendTransform(transformStamped transform)

    Latches a single static \a transform on \c /tf_static. Does nothing if the
    broadcaster is not yet connected to a \l Node.
*/
void QRos2StaticTransformBroadcaster::sendTransform(const Qtros2GeometryMsgs::TransformStamped& transform)
{
    if (!m_broadcaster)
        return;
    m_broadcaster->sendTransform(static_cast<geometry_msgs::msg::TransformStamped>(transform));
}

/*!
    \qmlmethod void StaticTransformBroadcaster::sendTransforms(list<transformStamped> transforms)

    Latches several static \a transforms on \c /tf_static in a single message.
*/
void QRos2StaticTransformBroadcaster::sendTransforms(const QList<Qtros2GeometryMsgs::TransformStamped>& transforms)
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
