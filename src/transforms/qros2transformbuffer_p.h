// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef QROS2_TRANSFORMBUFFER_P_H
#define QROS2_TRANSFORMBUFFER_P_H

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

#include <QtRos2Transforms/qtros2transformsexports.h>
#include <QtRos2GeometryMessages/msg/transform_stamped.hpp>
#include <QtCore/qobject.h>
#include <QtCore/qstring.h>
#include <QtGui/qquaternion.h>
#include <QtGui/qvector3d.h>
#ifndef Q_QDOC
#include <tf2_ros/buffer.hpp>
#include <tf2_msgs/msg/tf_message.hpp>
#include <rclcpp/rclcpp.hpp>
#include <atomic>
#include <memory>
#endif

QT_BEGIN_NAMESPACE

class QRos2Node;

// The TF tree of one Node: a tf2_ros::Buffer fed from the node's tf and
// tf_static topics. There is at most one per Node, created on first use by
// forNode() and owned by (parented to) that Node, so every FrameTransformer and
// FrameNode on the node shares it, and apps that never ask for a transform
// never subscribe to /tf. Since Node remaps /tf and /tf_static to relative
// names, the buffer follows the node's namespace.
//
// We subscribe ourselves rather than using tf2_ros::TransformListener so that
// (a) the buffer is filled on the QtRos2 executor (no extra spin thread) and
// (b) we get an update hook to emit transformsChanged() for QML bindings.
//
// It is not a NodeChild: it follows the node's initialized state through
// QRos2Node::initializedChanged, so it doesn't show up in Node::entities, and
// creating it from inside another entity's setupConnection() can't disturb the
// node's iteration over its entities.
class Q_ROS2TRANSFORMS_EXPORT QRos2TransformBuffer : public QObject
{
    Q_OBJECT

public:
    // The node's buffer, created on the first call.
    static QRos2TransformBuffer *forNode(QRos2Node *node);

    ~QRos2TransformBuffer() override;

    QRos2Node *node() const;

    // Latest transform expressing data in sourceFrame in terms of targetFrame.
    // Returns false (without logging) if it isn't currently resolvable.
    bool lookup(const QString &targetFrame, const QString &sourceFrame,
                QVector3D *translation, QQuaternion *rotation) const;

    // As above, as the QML value type. Returns a default-constructed value
    // (empty childFrameId) on failure, and logs a warning.
    Qtros2GeometryMsgs::TransformStamped lookupTransform(const QString &targetFrame,
                                                         const QString &sourceFrame) const;
    bool canTransform(const QString &targetFrame, const QString &sourceFrame) const;

#ifndef Q_QDOC
    // The tf2 buffer, or null while the node is not initialized. Use from the
    // node's thread only.
    std::shared_ptr<tf2_ros::Buffer> tf2Buffer() const { return m_buffer; }
#endif

Q_SIGNALS:
    // Emitted in this object's thread when /tf or /tf_static delivered new
    // transforms. Bursts of messages are coalesced into one emission per
    // event-loop pass.
    void transformsChanged();

private:
    explicit QRos2TransformBuffer(QRos2Node *node);
    void setupConnection();
    void clearConnection();
#ifndef Q_QDOC
    void ingest(tf2_ros::Buffer &buffer, const tf2_msgs::msg::TFMessage &msg, bool isStatic);

    std::shared_ptr<tf2_ros::Buffer> m_buffer;
    rclcpp::Subscription<tf2_msgs::msg::TFMessage>::SharedPtr m_tfSub;
    rclcpp::Subscription<tf2_msgs::msg::TFMessage>::SharedPtr m_tfStaticSub;
    std::atomic<bool> m_notifyPending = false;
#endif
};

QT_END_NAMESPACE

#endif // QROS2_TRANSFORMBUFFER_P_H
