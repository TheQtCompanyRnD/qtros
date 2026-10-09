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
#include <QtRos2Core/private/qros2nodechild_p.h>
#include <QtRos2GeometryMessages/msg/transform_stamped.hpp>
#include <QtRos2GeometryMessages/msg/point_stamped.hpp>
#include <QtRos2GeometryMessages/msg/pose_stamped.hpp>
#include <QtRos2GeometryMessages/msg/vector3_stamped.hpp>
#include <QtCore/qpointer.h>

QT_BEGIN_NAMESPACE

class QRos2TransformBuffer;

// FrameTransformer is the imperative receive side of QtRos2.Transforms: a
// handle onto its Node's QRos2TransformBuffer (the canonical time-windowed
// transform tree + interpolation + multi-hop chaining). Any number of them
// share the one buffer. The frame tree and time-history are implementation
// details: callers think in (source, target) pairs. Scenes that only need to
// place nodes use FrameNode (QtRos2.Quick3D) instead.
class Q_ROS2TRANSFORMS_EXPORT QRos2FrameTransformer : public QRos2NodeChild
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

    // Re-express stamped data in targetFrame, using the transform valid at the
    // data's own header.stamp. This is the everyday operation: the (source) frame
    // and time both come from the input. Returns a default-constructed value on
    // failure (and logs a warning).
    Q_INVOKABLE Qtros2GeometryMsgs::PointStamped transform(
        const Qtros2GeometryMsgs::PointStamped& in, const QString& targetFrame) const;
    Q_INVOKABLE Qtros2GeometryMsgs::PoseStamped transform(
        const Qtros2GeometryMsgs::PoseStamped& in, const QString& targetFrame) const;
    Q_INVOKABLE Qtros2GeometryMsgs::Vector3Stamped transform(
        const Qtros2GeometryMsgs::Vector3Stamped& in, const QString& targetFrame) const;

Q_SIGNALS:
    // Emitted (in this object's thread) whenever /tf or /tf_static delivers an
    // update, so QML bindings that call lookupTransform() re-evaluate.
    void transformsChanged();

private:
    QPointer<QRos2TransformBuffer> m_buffer;
};

QT_END_NAMESPACE

#endif // QROS2_FRAMETRANSFORMER_P_H
