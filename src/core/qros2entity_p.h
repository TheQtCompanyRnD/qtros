// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef QROS2_ENTITY_P_H
#define QROS2_ENTITY_P_H

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
#include "qros2nodechild_p.h"
#include <QString>
#ifndef Q_QDOC
#include <rmw/types.h>
#endif
#include "qros2qos_p.h"

QT_BEGIN_NAMESPACE

// A topic-based node child: everything that talks to a named topic or
// service endpoint with a QoS profile (publishers, subscribers, service
// and action clients/servers).
class Q_ROS2CORE_EXPORT QRos2Entity : public QRos2NodeChild
{
    Q_OBJECT

    Q_PROPERTY(QString topic READ topic WRITE setTopic NOTIFY topicChanged)
    Q_PROPERTY(QRos2QoS qos READ qos WRITE setQos NOTIFY qosChanged)

    QML_NAMED_ELEMENT(Entity)
    QML_UNCREATABLE("This is just abstract class")

public:
    explicit QRos2Entity(QObject* parent = nullptr);
    ~QRos2Entity() override = default;

    // QoS policy enums live on QRos2QualityOfService (QML: QualityOfService),
    // so they can be reached without going through an entity-derived type.

    QString topic() const { return m_topic; }
    void setTopic(const QString& topic);

    QRos2QoS qos() const { return m_qos; }
    void setQos(const QRos2QoS& qos);

Q_SIGNALS:
    void topicChanged();
    void qosChanged();

protected:
    QString m_topic;
    QRos2QoS m_qos;
};

QT_END_NAMESPACE

#endif // QROS2_ENTITY_P_H
