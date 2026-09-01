// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef QROS2_STATICTRANSFORMBROADCASTER_P_H
#define QROS2_STATICTRANSFORMBROADCASTER_P_H

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
#include <QList>
#ifndef Q_QDOC
#include <tf2_ros/static_transform_broadcaster.hpp>
#include <memory>
#endif

QT_BEGIN_NAMESPACE

class Q_ROS2TRANSFORMS_EXPORT QRos2StaticTransformBroadcaster : public QRos2Entity
{
    Q_OBJECT
    QML_NAMED_ELEMENT(StaticTransformBroadcaster)

    Q_PROPERTY(QList<Qtros2GeometryMsgs::TransformStamped> transforms
               READ transforms WRITE setTransforms NOTIFY transformsChanged)

public:
    explicit QRos2StaticTransformBroadcaster(QObject* parent = nullptr);

    QList<Qtros2GeometryMsgs::TransformStamped> transforms() const { return m_transforms; }
    void setTransforms(const QList<Qtros2GeometryMsgs::TransformStamped>& transforms);

    void setupConnection() override;
    void clearConnection() override;

public Q_SLOTS:
    void sendTransform(const Qtros2GeometryMsgs::TransformStamped& transform);
    void sendTransforms(const QList<Qtros2GeometryMsgs::TransformStamped>& transforms);

Q_SIGNALS:
    void transformsChanged();

private:
    QList<Qtros2GeometryMsgs::TransformStamped> m_transforms;
#ifndef Q_QDOC
    std::shared_ptr<tf2_ros::StaticTransformBroadcaster> m_broadcaster;
#endif
};

QT_END_NAMESPACE

#endif // QROS2_STATICTRANSFORMBROADCASTER_P_H
