// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef QROS2CONTEXTITEM_P_H
#define QROS2CONTEXTITEM_P_H

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
#include <QQmlParserStatus>
#include <QStringList>

QT_BEGIN_NAMESPACE

class Q_ROS2CORE_EXPORT QRos2ContextItem : public QObject, public QQmlParserStatus
{
    Q_OBJECT
    Q_PROPERTY(QStringList nodeArgs READ nodeArgs WRITE setNodeArgs NOTIFY nodeArgsChanged)
    Q_PROPERTY(bool multithreaded READ multithreaded WRITE setMultithreaded NOTIFY multithreadedChanged)
    Q_PROPERTY(int threadCount READ threadCount WRITE setThreadCount NOTIFY threadCountChanged)

    Q_INTERFACES(QQmlParserStatus)
    QML_NAMED_ELEMENT(Context)

public:
    explicit QRos2ContextItem(QObject *parent = nullptr);
    ~QRos2ContextItem() override;

    QStringList nodeArgs() const { return m_nodeArgs; }
    void setNodeArgs(const QStringList &args);

    bool multithreaded() const { return m_multithreaded; }
    void setMultithreaded(bool mt);

    int threadCount() const { return m_threadCount; }
    void setThreadCount(int n);

    void classBegin() override;
    void componentComplete() override;

Q_SIGNALS:
    void nodeArgsChanged();
    void multithreadedChanged();
    void threadCountChanged();

private:
    QStringList m_nodeArgs;
    int m_threadCount = 0;
    bool m_multithreaded = true;
    bool m_initialized = false;
};

QT_END_NAMESPACE

#endif // QROS2CONTEXTITEM_P_H
