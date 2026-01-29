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
    static void init(int argc, char **argv, bool useMultithreadedExecutor = false, size_t threadCount = 0);
    static QROS2Context &instance();

    std::shared_ptr<rclcpp::Executor> executor() const { return m_executor; }

    QROS2Context(const QROS2Context &) = delete;
    QROS2Context &operator=(const QROS2Context &) = delete;

private:
    QROS2Context();
    void initialize(int argc, char **argv, bool useMultithreadedExecutor, size_t threadCount);
    ~QROS2Context();

    bool m_initialized = false;
    std::shared_ptr<rclcpp::Executor> m_executor;
    std::thread m_spinThread;
};

#endif // QROS2_CONTEXT_H
