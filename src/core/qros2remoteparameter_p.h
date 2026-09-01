// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef QROS2_REMOTEPARAMETER_P_H
#define QROS2_REMOTEPARAMETER_P_H

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
#include <QVariant>
#ifndef Q_QDOC
#include <rclcpp/rclcpp.hpp>
#include <rcl_interfaces/msg/parameter_event.hpp>
#endif

QT_BEGIN_NAMESPACE

class Q_ROS2CORE_EXPORT QRos2RemoteParameter : public QRos2NodeChild
{
    Q_OBJECT
    QML_NAMED_ELEMENT(RemoteParameter)

    Q_PROPERTY(QString remoteNode READ remoteNode WRITE setRemoteNode NOTIFY remoteNodeChanged)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QVariant value READ value WRITE setValue NOTIFY valueChanged)
    Q_PROPERTY(QVariant reported READ reported NOTIFY reportedChanged)
    Q_PROPERTY(bool ready READ isReady NOTIFY readyChanged)
    Q_PROPERTY(bool pending READ isPending NOTIFY pendingChanged)
    Q_PROPERTY(bool autoApply READ autoApply WRITE setAutoApply NOTIFY autoApplyChanged)

public:
    explicit QRos2RemoteParameter(QObject* parent = nullptr);
    ~QRos2RemoteParameter() override;

    QString remoteNode() const { return m_remoteNode; }
    void setRemoteNode(const QString& remoteNode);

    QString name() const { return m_name; }
    void setName(const QString& name);

    QVariant value() const { return m_value; }
    void setValue(const QVariant& value);

    QVariant reported() const { return m_reported; }

    bool isReady() const { return m_ready; }
    bool isPending() const { return m_pending; }

    bool autoApply() const { return m_autoApply; }
    void setAutoApply(bool autoApply);

    Q_INVOKABLE void apply();
    Q_INVOKABLE void refresh();

    void setupConnection() override;
    void clearConnection() override;
    void checkHealth() override;

Q_SIGNALS:
    void remoteNodeChanged();
    void nameChanged();
    void valueChanged();
    void reportedChanged();
    void readyChanged();
    void pendingChanged();
    void autoApplyChanged();
    void setFailed(QString reason);

private:
    QString resolvedRemoteNode() const;
    void scheduleApplyAttempt();
    void attemptApply(bool force = false);
    void updateReported(const QVariant& value);
    void handleSetResult(bool successful, const QString& reason);
    void reconnect();

    QString m_remoteNode;
    QString m_name;
    QVariant m_value;
    QVariant m_reported;
    bool m_ready = false;
    bool m_pending = false;
    bool m_autoApply = true;
    bool m_dirty = false;
    bool m_attemptScheduled = false;
    bool m_reportedFetched = false;

#ifndef Q_QDOC
    rclcpp::AsyncParametersClient::SharedPtr m_client;
    rclcpp::Subscription<rcl_interfaces::msg::ParameterEvent>::SharedPtr m_eventSub;
#endif
};

QT_END_NAMESPACE

#endif // QROS2_REMOTEPARAMETER_P_H
