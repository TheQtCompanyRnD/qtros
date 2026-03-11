// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef QROS2_CONTEXT_H
#define QROS2_CONTEXT_H

#include <cstddef>
#include <memory>
#include <rclcpp/executors/multi_threaded_executor.hpp>
#include <rclcpp/executors/single_threaded_executor.hpp>
#include <rclcpp/rclcpp.hpp>
#include <thread>

#include <QtCore/QtGlobal>
#include <QtRos2Core/qtros2coreexports.h>

QT_BEGIN_NAMESPACE

class Q_ROS2CORE_EXPORT QRos2Context
{
public:
    static void init(int argc, char **argv, bool useMultithreadedExecutor = false, size_t threadCount = 0)
    {
        auto &ctx = instance();
        ctx.initialize(argc, argv, useMultithreadedExecutor, threadCount);
    }

    static QRos2Context &instance()
    {
        static QRos2Context ctx;
        return ctx;
    }

    std::shared_ptr<rclcpp::Executor> executor() const { return m_executor; }

    QRos2Context(const QRos2Context &) = delete;
    QRos2Context &operator=(const QRos2Context &) = delete;

private:
    QRos2Context() = default;

    void initialize(int argc, char **argv, bool useMultithreadedExecutor, size_t threadCount)
    {
        if (m_initialized)
            return;

        rclcpp::init(argc, argv);

        if (useMultithreadedExecutor) {
            rclcpp::ExecutorOptions options;
            m_executor = std::make_shared<rclcpp::executors::MultiThreadedExecutor>(options, threadCount);
        } else {
            m_executor = std::make_shared<rclcpp::executors::SingleThreadedExecutor>();
        }

        m_spinThread = std::thread([this]() { m_executor->spin(); });

        m_initialized = true;
    }

    ~QRos2Context()
    {
        if (!m_initialized)
            return;

        if (m_executor) {
            m_executor->cancel();
        }

        if (m_spinThread.joinable()) {
            m_spinThread.join();
        }

        if (rclcpp::ok()) {
            rclcpp::shutdown();
        }
    }

    bool m_initialized = false;
    std::shared_ptr<rclcpp::Executor> m_executor;
    std::thread m_spinThread;
};

QT_END_NAMESPACE

#endif // QROS2_CONTEXT_H
