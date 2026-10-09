// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2framenode_p.h"
#include <QtRos2Transforms/private/qros2transformbuffer_p.h>

#include <QLoggingCategory>

QT_BEGIN_NAMESPACE

Q_STATIC_LOGGING_CATEGORY(lcFrameNode, "qt.robotics.framenode")

/*!
    \qmltype FrameNode
    \inqmlmodule QtRos2.Quick3D
    \inherits QtQuick3D::Node
    \brief A Qt Quick 3D Node that follows a coordinate frame in the TF tree.

    FrameNode places itself at the TF frame named by \l frame: its \c position
    and \c rotation are kept equal to the transform of \l frame relative to
    \l parentFrame, which by default is the frame of the nearest FrameNode
    ancestor. Nest FrameNodes the way the frames are nested in the robot, and
    give each one only its own frame name:

    \qml
    import QtQuick3D
    import QtRos2.Core as Ros2
    import QtRos2.Quick3D

    Ros2.Node { id: rosNode; nodeName: "viewer" }

    FrameNode {
        frame: "map"                // the fixed frame: left where you put it
        rosNode: rosNode            // inherited by the FrameNodes inside

        OccupancyGridModel { }      // anything drawn in map coordinates

        FrameNode {
            frame: "base_link"      // follows map -> odom -> base_link
            RobotModel { }

            FrameNode {
                frame: "laser"      // follows base_link -> laser
                LaserScanModel { }
            }
        }
    }
    \endqml

    The transforms come from the TF buffer of \l rosNode, which listens to the
    node's \c tf and \c tf_static topics. That buffer is shared with every
    other FrameNode and \l FrameTransformer on the same Node, and is created
    the first time something needs it.

    \section2 Frames that are not in the scene

    A FrameNode's \l parentFrame does not need to be the frame's direct parent
    in the TF tree: TF composes the transforms in between. In the example
    above, \c base_link is placed relative to \c map even though TF relates
    them only through \c odom. Add FrameNodes only for the frames you want to
    draw something in.

    \section2 Nodes between FrameNodes

    Ordinary Nodes may sit between a FrameNode and its FrameNode ancestor; a
    FrameNode looks past them. Their own transforms still apply on top, which
    is useful for presentation, such as scaling a model, but a rotation or
    translation there moves everything inside away from where TF says it is.

    \section2 Units and axes

    TF uses meters, and ROS uses a right-handed coordinate system with \c Z
    up. FrameNode sets ROS values directly, so the units and axes of the scene
    inside the root FrameNode are those of ROS. To view it in Qt Quick 3D's
    usual \c Y-up, centimeter scene, put the root FrameNode inside a Node that
    converts once:

    \qml
    Node {
        scale: Qt.vector3d(100, 100, 100)       // meters to scene units
        eulerRotation.x: -90                    // ROS Z-up to Qt Quick 3D Y-up
        FrameNode { frame: "map"; rosNode: rosNode; ... }
    }
    \endqml

    \sa FrameTransformer
*/

/*!
    \qmlproperty string FrameNode::frame

    The TF frame this node follows; for example \c "base_link".

    If the root FrameNode (one without a FrameNode ancestor and without
    \l parentFrame) has a frame, it is not moved: it defines where that frame
    is in the scene, and the FrameNodes inside are positioned relative to it.
*/

/*!
    \qmlproperty string FrameNode::parentFrame

    The frame that \l frame is positioned relative to. By default this is the
    \l frame of the nearest FrameNode ancestor, which is what a scene that
    mirrors the TF tree needs. Set it to override that; reset it with
    \c undefined to go back to the default.

    Reading this property returns the frame in effect. It is empty for a root
    FrameNode, which keeps the position and rotation it was given.
*/

/*!
    \qmlproperty Node FrameNode::rosNode

    The ROS 2 \l {QtRos2.Core::Node}{Node} whose TF tree this FrameNode reads. By
    default it is inherited from the nearest FrameNode ancestor, so it normally
    needs to be set only on the root FrameNode. Reset it with \c undefined to
    go back to the inherited one.
*/

/*!
    \qmlproperty bool FrameNode::valid
    \readonly

    \c true when the node's position and rotation reflect the transform from
    \l parentFrame to \l frame: that is, once that transform has been received.
    It becomes \c false if the transform can no longer be resolved, and the
    node then stays where it was last placed. A root FrameNode is always
    valid.

    Bind \c visible to it to hide a part of the scene until TF has placed it:

    \qml
    FrameNode {
        frame: "base_link"
        visible: valid
        RobotModel { }
    }
    \endqml
*/

QRos2FrameNode::QRos2FrameNode(QQuick3DNode *parent)
    : QQuick3DNode(parent)
{
}

QRos2FrameNode::~QRos2FrameNode() = default;

void QRos2FrameNode::setFrame(const QString &frame)
{
    if (m_frame == frame)
        return;
    m_frame = frame;
    emit frameChanged();
    // Descendants without an explicit parentFrame inherit this frame.
    hierarchyChanged();
}

QString QRos2FrameNode::parentFrame() const
{
    if (!m_parentFrame.isEmpty())
        return m_parentFrame;
    const QRos2FrameNode *ancestor = frameAncestor();
    return ancestor ? ancestor->frame() : QString();
}

void QRos2FrameNode::setParentFrame(const QString &parentFrame)
{
    if (m_parentFrame == parentFrame)
        return;
    m_parentFrame = parentFrame;
    emit parentFrameChanged();
    updateTransform();
}

void QRos2FrameNode::resetParentFrame()
{
    setParentFrame(QString());
}

QRos2Node *QRos2FrameNode::rosNode() const
{
    for (const QRos2FrameNode *n = this; n; n = n->frameAncestor()) {
        if (n->m_rosNode)
            return n->m_rosNode;
    }
    return nullptr;
}

void QRos2FrameNode::setRosNode(QRos2Node *node)
{
    if (m_rosNode == node)
        return;
    m_rosNode = node;
    hierarchyChanged();
}

void QRos2FrameNode::resetRosNode()
{
    setRosNode(nullptr);
}

QRos2FrameNode *QRos2FrameNode::frameAncestor() const
{
    for (QQuick3DObject *p = parentItem(); p; p = p->parentItem()) {
        if (auto *frameNode = qobject_cast<QRos2FrameNode *>(p))
            return frameNode;
    }
    return nullptr;
}

void QRos2FrameNode::componentComplete()
{
    QQuick3DNode::componentComplete();
    reconnect();
    updateTransform();
}

void QRos2FrameNode::itemChange(ItemChange change, const ItemChangeData &data)
{
    QQuick3DNode::itemChange(change, data);
    if (change == ItemParentHasChanged)
        hierarchyChanged();
}

void QRos2FrameNode::hierarchyChanged()
{
    // The values in effect may have changed; cheaper to notify than to compare.
    emit parentFrameChanged();
    emit rosNodeChanged();
    reconnect();
    updateTransform();

    // FrameNode descendants, however deep, may inherit from this one. Each
    // FrameNode found handles its own subtree.
    QList<QQuick3DObject *> pending = childItems();
    while (!pending.isEmpty()) {
        QQuick3DObject *child = pending.takeLast();
        if (auto *frameNode = qobject_cast<QRos2FrameNode *>(child))
            frameNode->hierarchyChanged();
        else
            pending.append(child->childItems());
    }
}

void QRos2FrameNode::reconnect()
{
    if (!isComponentComplete())
        return;
    QRos2TransformBuffer *buffer = QRos2TransformBuffer::forNode(rosNode());
    if (buffer == m_buffer)
        return;
    if (m_buffer)
        disconnect(m_buffer, nullptr, this, nullptr);
    m_buffer = buffer;
    if (m_buffer) {
        connect(m_buffer, &QRos2TransformBuffer::transformsChanged,
                this, &QRos2FrameNode::updateTransform);
    }
}

void QRos2FrameNode::updateTransform()
{
    if (!isComponentComplete())
        return;

    const QString target = parentFrame();
    if (target.isEmpty()) {
        // The root: it defines where its frame is, so it stays put.
        setValid(true);
        return;
    }
    if (m_frame.isEmpty()) {
        setValid(false);
        return;
    }
    if (m_frame == target) {
        setPosition(QVector3D());
        setRotation(QQuaternion());
        setValid(true);
        return;
    }
    if (!m_buffer) {
        qCDebug(lcFrameNode) << this << m_frame << "has no rosNode to look up transforms in";
        setValid(false);
        return;
    }

    QVector3D translation;
    QQuaternion rotation;
    if (m_buffer->lookup(target, m_frame, &translation, &rotation)) {
        setPosition(translation);
        setRotation(rotation);
        setValid(true);
    } else {
        setValid(false);
    }
}

void QRos2FrameNode::setValid(bool valid)
{
    if (m_valid == valid)
        return;
    m_valid = valid;
    emit validChanged();
}

QT_END_NAMESPACE
