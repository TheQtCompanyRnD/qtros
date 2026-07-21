// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef QROS2_NODECHILD_P_H
#define QROS2_NODECHILD_P_H

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

#include <QtRos2Core/qtros2coreexports.h>
#include <QObject>
#include <QQmlEngine>

QT_BEGIN_NAMESPACE

class QRos2Node;
Q_MOC_INCLUDE(<QtRos2Core/private/qros2node_p.h>)

// The minimal contract for anything that can live inside a Node: attachment
// to the node plus the setup/clear/health lifecycle driven by the node.
// Topic-based entities extend this with topic/qos (QRos2Entity); non-topic
// children (e.g. parameters) derive directly.
class Q_ROS2CORE_EXPORT QRos2NodeChild : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QRos2Node* node READ node WRITE setNode NOTIFY nodeChanged)

    QML_NAMED_ELEMENT(NodeChild)
    QML_UNCREATABLE("This is just abstract class")

public:
    explicit QRos2NodeChild(QObject* parent = nullptr);
    ~QRos2NodeChild() override;

    QRos2Node* node() const { return m_node; }
    void setNode(QRos2Node* node);

    // Called when parent node is initialized to setup the ROS2 connection
    virtual void setupConnection() = 0;
    virtual void clearConnection() = 0;

    // Called periodically by QRos2Node to update connection state
    virtual void checkHealth() {}

Q_SIGNALS:
    void nodeChanged();

protected:
    QRos2Node* m_node = nullptr;

    friend class QRos2Node;
};

QT_END_NAMESPACE

#endif // QROS2_NODECHILD_P_H
