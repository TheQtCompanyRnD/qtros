// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef QROS2_CONTEXT_H
#define QROS2_CONTEXT_H

#include <cstddef>
#include <memory>
#include <thread>

#include <QtCore/QtGlobal>
#include <QtRos2Core/qtros2coreexports.h>

namespace rclcpp { class Executor; }

QT_BEGIN_NAMESPACE

class Q_ROS2CORE_EXPORT QRos2Context
{
public:
    static bool isInitialized();
    static void init();
    static void init(int argc, char **argv, bool useMultithreadedExecutor = false, size_t threadCount = 0);
    static QRos2Context &instance();
    const std::shared_ptr<rclcpp::Executor> &executor() const;

private:
    friend class QRos2ContextItem;

    QRos2Context() = default;
    QRos2Context(const QRos2Context &) = delete;
    QRos2Context &operator=(const QRos2Context &) = delete;
    ~QRos2Context();

    static void initFromContextItem(const QStringList &nodeArgs, bool useMultithreaded, size_t threadCount);
    void initialize(int argc, char **argv, bool useMultithreadedExecutor, size_t threadCount);

    bool m_initialized = false;
    std::shared_ptr<rclcpp::Executor> m_executor;
    std::thread m_spinThread;
};

QT_END_NAMESPACE

#endif // QROS2_CONTEXT_H
