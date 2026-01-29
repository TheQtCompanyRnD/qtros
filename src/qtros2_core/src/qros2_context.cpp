// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include <qtros2_core/qros2_context.hpp>

void QROS2Context::init(int argc, char **argv, bool useMultithreadedExecutor, size_t threadCount)
{
    auto &ctx = instance();
    ctx.initialize(argc, argv, useMultithreadedExecutor, threadCount);
}

QROS2Context &QROS2Context::instance()
{
    static QROS2Context ctx;
    return ctx;
}

QROS2Context::QROS2Context() = default;

void QROS2Context::initialize(int argc, char **argv, bool useMultithreadedExecutor, size_t threadCount)
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

QROS2Context::~QROS2Context()
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
