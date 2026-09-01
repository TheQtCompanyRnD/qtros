// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef QROS2_PUBLISHERBASE_P_H
#define QROS2_PUBLISHERBASE_P_H

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
#include <QBasicTimer>
#include "qros2entity_p.h"
#include "qros2node_p.h"

class Q_ROS2CORE_EXPORT QRos2PublisherBase : public QRos2Entity
{
    Q_OBJECT
    QML_NAMED_ELEMENT(PublisherBase)
    QML_UNCREATABLE("Abstract")

    Q_PROPERTY(int subscriberCount READ subscriberCount NOTIFY subscriberCountChanged)
    Q_PROPERTY(bool autoPublish READ autoPublish WRITE setAutoPublish NOTIFY autoPublishChanged)
    Q_PROPERTY(int publishInterval READ publishInterval WRITE setPublishInterval NOTIFY publishIntervalChanged)

public:
    explicit QRos2PublisherBase(QObject* parent = nullptr);

    int subscriberCount() const { return m_subscriberCount; }

    bool autoPublish() const { return m_autoPublish; }
    void setAutoPublish(bool autoPublish);

    int publishInterval() const { return m_publishInterval; }
    void setPublishInterval(int ms);

    Q_INVOKABLE void publish();

Q_SIGNALS:
    void subscriberCountChanged();
    void autoPublishChanged();
    void publishIntervalChanged();

protected:
    void setSubscriberCount(int count);
    void requestPublish();
    virtual void publishStoredState();
    void timerEvent(QTimerEvent* event) override;

    // Called by generated setupConnection() after the rcl publisher is
    // (re)created: latched (transient_local) topics republish the stored
    // state so late-joining subscriptions see the current value even if
    // it was bound before the node initialized.
    bool shouldRepublishOnConnect() const;

private:
    QBasicTimer m_publishTimer;
    int m_subscriberCount = 0;
    int m_publishInterval = 0;
    bool m_autoPublish = true;
    bool m_publishPending = false;
    bool m_storedStateWritten = false;
};

#endif // QROS2_PUBLISHERBASE_P_H
