// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef QROS2_CONTEXT_H
#define QROS2_CONTEXT_H

#include <cstddef>
#include <memory>
#include <rclcpp/executors/multi_threaded_executor.hpp>
#include <rclcpp/executors/single_threaded_executor.hpp>
#include <rclcpp/rclcpp.hpp>
#include <thread>

class QROS2Context
{
public:
    static void init(int argc, char **argv, bool useMultithreadedExecutor = false, size_t threadCount = 0)
    {
        auto &ctx = instance();
        ctx.initialize(argc, argv, useMultithreadedExecutor, threadCount);
    }

    static QROS2Context &instance()
    {
        static QROS2Context ctx;
        return ctx;
    }

    std::shared_ptr<rclcpp::Executor> executor() const { return m_executor; }

    QROS2Context(const QROS2Context &) = delete;
    QROS2Context &operator=(const QROS2Context &) = delete;

private:
    QROS2Context() = default;

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

    ~QROS2Context()
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

#endif // QROS2_CONTEXT_H
