// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef QROS2_FRAMENODE_P_H
#define QROS2_FRAMENODE_P_H

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

#include <QtRos2Quick3D/qtros2quick3dexports.h>
#include <QtRos2Core/private/qros2node_p.h>
#include <QtQuick3D/private/qquick3dnode_p.h>
#include <QtCore/qpointer.h>

QT_BEGIN_NAMESPACE

class QRos2TransformBuffer;

// A Qt Quick 3D Node that sits at a TF frame. Its position and rotation are
// the transform of `frame` relative to its nearest FrameNode ancestor's frame
// (or to `parentFrame`, if set), looked up in the Node's shared TF buffer
// whenever new transforms arrive. So a hierarchy of FrameNodes mirrors (a
// subset of) the TF tree, each one needing only its own frame name; plain
// Nodes in between are presentation-only transforms (scale, mesh offsets).
class Q_ROS2QUICK3D_EXPORT QRos2FrameNode : public QQuick3DNode
{
    Q_OBJECT
    Q_PROPERTY(QString frame READ frame WRITE setFrame NOTIFY frameChanged FINAL)
    Q_PROPERTY(QString parentFrame READ parentFrame WRITE setParentFrame RESET resetParentFrame
               NOTIFY parentFrameChanged FINAL)
    Q_PROPERTY(QRos2Node *rosNode READ rosNode WRITE setRosNode RESET resetRosNode
               NOTIFY rosNodeChanged FINAL)
    Q_PROPERTY(bool valid READ isValid NOTIFY validChanged FINAL)
    QML_NAMED_ELEMENT(FrameNode)

public:
    explicit QRos2FrameNode(QQuick3DNode *parent = nullptr);
    ~QRos2FrameNode() override;

    QString frame() const { return m_frame; }
    void setFrame(const QString &frame);

    // The explicit parentFrame if set, otherwise the nearest FrameNode
    // ancestor's frame; empty for a root FrameNode.
    QString parentFrame() const;
    void setParentFrame(const QString &parentFrame);
    void resetParentFrame();

    // The explicit rosNode if set, otherwise the nearest FrameNode ancestor's.
    QRos2Node *rosNode() const;
    void setRosNode(QRos2Node *node);
    void resetRosNode();

    bool isValid() const { return m_valid; }

Q_SIGNALS:
    void frameChanged();
    void parentFrameChanged();
    void rosNodeChanged();
    void validChanged();

protected:
    void componentComplete() override;
    void itemChange(ItemChange change, const ItemChangeData &data) override;

private:
    QRos2FrameNode *frameAncestor() const;
    void updateTransform();
    void setValid(bool valid);
    // Re-resolve inherited properties here and in all FrameNode descendants,
    // after something they may inherit from has changed.
    void hierarchyChanged();
    void reconnect();

    QString m_frame;
    QString m_parentFrame; // explicit; empty means inherit
    QPointer<QRos2Node> m_rosNode; // explicit; null means inherit
    QPointer<QRos2TransformBuffer> m_buffer;
    bool m_valid = false;
};

QT_END_NAMESPACE

#endif // QROS2_FRAMENODE_P_H
