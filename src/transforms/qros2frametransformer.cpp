// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2frametransformer_p.h"
#include "qros2transformbuffer_p.h"
#include <QtRos2Core/private/qros2node_p.h>

#include <QLoggingCategory>
#ifndef Q_QDOC
#include <tf2/exceptions.hpp>
#include <tf2_geometry_msgs/tf2_geometry_msgs.hpp>  // doTransform specializations
#endif

QT_BEGIN_NAMESPACE

Q_STATIC_LOGGING_CATEGORY(lcFrameTransformer, "qt.robotics.transforms")

namespace {
// Convert the QML value type to its ROS message, run tf2's typed transform
// (which reads header.stamp/frame_id and applies doTransform), and wrap back.
template<class QtType, class RosType>
QtType transformStamped(const QRos2TransformBuffer* buffer,
                        const QtType& in, const QString& targetFrame)
{
    const auto tf2Buffer = buffer ? buffer->tf2Buffer() : nullptr;
    if (!tf2Buffer)
        return {};
    try {
        return QtType(tf2Buffer->transform(static_cast<RosType>(in), targetFrame.toStdString()));
    } catch (const tf2::TransformException& ex) {
        qCWarning(lcFrameTransformer) << "transform to" << targetFrame << "failed:" << ex.what();
        return {};
    }
}
} // namespace

/*!
    \qmltype FrameTransformer
    \inqmlmodule QtRos2.Transforms
    \inherits NodeChild
    \brief Looks up coordinate-frame transforms from the TF tree.

    FrameTransformer gives imperative access to the TF tree of the \l Node it
    belongs to: ask it for the transform between any two connected frames with
    \l lookupTransform, or re-express stamped data in another frame with
    \l transform. The multi-hop path, the time history, and the interpolation
    are handled for you.

    Each Node keeps a single TF buffer, fed from its \c tf and \c tf_static
    topics (which resolve under the node's namespace), and creates it the first
    time something asks for a transform. Any number of FrameTransformer and
    \l {QtRos2.Quick3D::FrameNode}{FrameNode} items on the same Node share that buffer, so
    declaring another one costs nothing.

    \qml
    Node {
        nodeName: "my_qt_node"
        FrameTransformer { id: tf }
    }
    // ... later, e.g. to express a clicked point in the map frame:
    const p = tf.transform(clickedPoint, "map")
    \endqml

    To place Qt Quick 3D nodes at TF frames, use \l {QtRos2.Quick3D::FrameNode}{FrameNode}
    instead: it binds a node to a frame without any code.

    Bindings that call \l lookupTransform re-evaluate on \c transformsChanged,
    which fires whenever new transforms arrive.

    \sa TransformBroadcaster, StaticTransformBroadcaster
*/

QRos2FrameTransformer::QRos2FrameTransformer(QObject* parent)
    : QRos2NodeChild(parent)
{
}

// Called on attachment to a node and again when the node initializes; the
// buffer itself follows the node's lifecycle, so this only (re)binds to it.
void QRos2FrameTransformer::setupConnection()
{
    QRos2TransformBuffer* buffer = QRos2TransformBuffer::forNode(node());
    if (buffer == m_buffer)
        return;
    if (m_buffer)
        disconnect(m_buffer, nullptr, this, nullptr);
    m_buffer = buffer;
    if (m_buffer) {
        connect(m_buffer, &QRos2TransformBuffer::transformsChanged,
                this, &QRos2FrameTransformer::transformsChanged);
    }
}

void QRos2FrameTransformer::clearConnection()
{
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
    return m_buffer ? m_buffer->lookupTransform(targetFrame, sourceFrame)
                    : Qtros2GeometryMsgs::TransformStamped();
}

/*!
    \qmlmethod bool FrameTransformer::canTransform(string targetFrame, string sourceFrame)

    Returns \c true if the latest \a sourceFrame to \a targetFrame transform is
    currently resolvable from the TF tree.
*/
bool QRos2FrameTransformer::canTransform(
    const QString& targetFrame, const QString& sourceFrame) const
{
    return m_buffer && m_buffer->canTransform(targetFrame, sourceFrame);
}

/*!
    \qmlmethod pointStamped FrameTransformer::transform(pointStamped in, string targetFrame)

    Re-expresses the stamped point \a in into \a targetFrame, using the transform
    valid at \c{in.header.stamp}.
*/
Qtros2GeometryMsgs::PointStamped QRos2FrameTransformer::transform(
    const Qtros2GeometryMsgs::PointStamped& in, const QString& targetFrame) const
{
    return transformStamped<Qtros2GeometryMsgs::PointStamped,
                            geometry_msgs::msg::PointStamped>(m_buffer.data(), in, targetFrame);
}

/*!
    \qmlmethod poseStamped FrameTransformer::transform(poseStamped in, string targetFrame)

    Re-expresses the stamped pose \a in into \a targetFrame, using the transform
    valid at \c{in.header.stamp}.
*/
Qtros2GeometryMsgs::PoseStamped QRos2FrameTransformer::transform(
    const Qtros2GeometryMsgs::PoseStamped& in, const QString& targetFrame) const
{
    return transformStamped<Qtros2GeometryMsgs::PoseStamped,
                            geometry_msgs::msg::PoseStamped>(m_buffer.data(), in, targetFrame);
}

/*!
    \qmlmethod vector3Stamped FrameTransformer::transform(vector3Stamped in, string targetFrame)

    Re-expresses the stamped vector \a in into \a targetFrame, using the transform
    valid at \c{in.header.stamp}.
*/
Qtros2GeometryMsgs::Vector3Stamped QRos2FrameTransformer::transform(
    const Qtros2GeometryMsgs::Vector3Stamped& in, const QString& targetFrame) const
{
    return transformStamped<Qtros2GeometryMsgs::Vector3Stamped,
                            geometry_msgs::msg::Vector3Stamped>(m_buffer.data(), in, targetFrame);
}

QT_END_NAMESPACE
