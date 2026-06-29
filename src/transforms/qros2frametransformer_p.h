// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef QROS2_FRAMETRANSFORMER_P_H
#define QROS2_FRAMETRANSFORMER_P_H

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
#include <QtRos2Core/private/qros2entity_p.h>
#include <QtRos2GeometryMessages/msg/transform_stamped.hpp>
#ifndef Q_QDOC
#include <tf2_ros/buffer.hpp>
#include <tf2_msgs/msg/tf_message.hpp>
#include <rclcpp/rclcpp.hpp>
#include <memory>
#endif

QT_BEGIN_NAMESPACE

// FrameTransformer is the receive side of QtRos2.Transforms. It owns a
// tf2_ros::Buffer (the canonical time-windowed transform tree + interpolation
// + multi-hop chaining) and feeds it from its own /tf and /tf_static
// subscriptions. We subscribe ourselves rather than using
// tf2_ros::TransformListener so that (a) the buffer is filled on the QtRos2
// executor (no extra spin thread) and (b) we get an update hook to emit
// transformsChanged() for QML bindings. The frame tree and time-history are
// implementation details: callers think in (source, target) pairs.
class Q_ROS2TRANSFORMS_EXPORT QRos2FrameTransformer : public QRos2Entity
{
    Q_OBJECT
    QML_NAMED_ELEMENT(FrameTransformer)

public:
    explicit QRos2FrameTransformer(QObject* parent = nullptr);

    void setupConnection() override;
    void clearConnection() override;

    // Latest transform expressing data in sourceFrame in terms of targetFrame.
    // Returns a default-constructed (empty childFrameId) value on failure; check
    // with canTransform() first, or test the returned childFrameId.
    Q_INVOKABLE Qtros2GeometryMsgs::TransformStamped lookupTransform(
        const QString& targetFrame, const QString& sourceFrame) const;

    // True if the latest sourceFrame->targetFrame transform is currently available.
    Q_INVOKABLE bool canTransform(const QString& targetFrame, const QString& sourceFrame) const;

Q_SIGNALS:
    // Emitted (in this object's thread) whenever /tf or /tf_static delivers an
    // update, so QML bindings that call lookupTransform() re-evaluate.
    void transformsChanged();

private:
#ifndef Q_QDOC
    void ingest(const tf2_msgs::msg::TFMessage& msg, bool isStatic);

    std::shared_ptr<tf2_ros::Buffer> m_buffer;
    rclcpp::Subscription<tf2_msgs::msg::TFMessage>::SharedPtr m_tfSub;
    rclcpp::Subscription<tf2_msgs::msg::TFMessage>::SharedPtr m_tfStaticSub;
#endif
};

QT_END_NAMESPACE

#endif // QROS2_FRAMETRANSFORMER_P_H
