// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2context.h"

#include <rclcpp/executors/multi_threaded_executor.hpp>
#include <rclcpp/executors/single_threaded_executor.hpp>
#include <rclcpp/rclcpp.hpp>

#include <QtCore/qcoreapplication.h>
#include <QtCore/qdebug.h>
#include <QtCore/qlist.h>

#include <QtGui/private/qguiapplication_p.h>

QT_BEGIN_NAMESPACE

Q_STATIC_LOGGING_CATEGORY(lcCtx, "qt.robotics.context")

bool QRos2Context::isInitialized()
{
    return instance().m_initialized;
}

void QRos2Context::init()
{
    if (auto *qGuiAppPrivate = QGuiApplicationPrivate::instance()) {
        int argc = qGuiAppPrivate->argc;
        char **argv = qGuiAppPrivate->argv;
        instance().initialize(argc, argv, true, 0);
    } else {
        qCWarning(lcCtx) << "No GUI Application found! Initializing rclcpp without options!";
        instance().initialize(0, nullptr, false, 0);
    }
}

void QRos2Context::init(int argc, char **argv, bool useMultithreadedExecutor, size_t threadCount)
{
    auto &ctx = instance();
    ctx.initialize(argc, argv, useMultithreadedExecutor, threadCount);
}

QRos2Context &QRos2Context::instance()
{
    static QRos2Context ctx;
    return ctx;
}

const std::shared_ptr<rclcpp::Executor> &QRos2Context::executor() const { return m_executor; }

void QRos2Context::initFromContextItem(const QStringList &nodeArgs, bool useMultithreaded, size_t threadCount)
{
    if (isInitialized())
        return;

    // Each argument string is stored in a separate QByteArray so we can
    // obtain stable char* pointers. Both containers are static to ensure
    // the data outlives this call (required by rclcpp which may retain
    // pointers internally, and to be explicit about ownership).
    static QList<QByteArray> argStorage;
    static std::vector<char *> argv_vec;

    Q_ASSERT(argStorage.isEmpty());

    // Prepend the application's own argv so ROS2 sees any command-line
    // arguments that were passed to the process (e.g. --ros-args from the
    // terminal), then append the extra args from the Ros2Context QML item.
    if (auto *qGuiAppPrivate = QGuiApplicationPrivate::instance()) {
        const int argc = qGuiAppPrivate->argc;
        char **argv = qGuiAppPrivate->argv;
        for (int i = 0; i < argc; ++i) {
            argStorage.push_back(QByteArray(argv[i]));
            argv_vec.push_back(argStorage.back().data());
        }
    }

    for (const QString &arg : std::as_const(nodeArgs)) {
        argStorage.push_back(arg.toUtf8());
        argv_vec.push_back(argStorage.back().data());
    }

    instance().initialize(static_cast<int>(argv_vec.size()), argv_vec.data(), useMultithreaded, threadCount);
}

void QRos2Context::initialize(int argc, char **argv, bool useMultithreadedExecutor, size_t threadCount)
{
    if (m_initialized)
        return;

    QList<QByteArrayView> args;
    for (int i = 0; i < argc; ++i)
        args << argv[i];
    qCInfo(lcCtx) << "init context with args" << args << "threads?" << useMultithreadedExecutor << threadCount;

    rclcpp::init(argc, argv);

    // rclcpp's signal handler calls rclcpp::shutdown() on SIGINT/SIGTERM but does not stop
    // the Qt event loop, so the process would otherwise stay alive and have to be killed
    // (SIGKILL skips destructors, leaving the DDS participant's FastDDS shared-memory port
    // mutex locked and deadlocking the next process to start). Quitting the event loop lets
    // main() return normally so nodes and ~QRos2Context tear down the participant cleanly.
    // rclcpp dispatches on_shutdown from its own thread, so post the quit via a queued
    // connection. Guarding on instance() also covers headless QCoreApplication daemons.
    rclcpp::on_shutdown([] {
        if (auto *app = QCoreApplication::instance())
            QMetaObject::invokeMethod(app, &QCoreApplication::quit, Qt::QueuedConnection);
    });

    if (useMultithreadedExecutor) {
        rclcpp::ExecutorOptions options;
        m_executor = std::make_shared<rclcpp::executors::MultiThreadedExecutor>(options, threadCount);
    } else {
        m_executor = std::make_shared<rclcpp::executors::SingleThreadedExecutor>();
    }

    m_spinThread = std::thread([this]() { m_executor->spin(); });

    m_initialized = true;
}

QRos2Context::~QRos2Context()
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

QT_END_NAMESPACE
