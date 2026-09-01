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

/*!
    \class QRos2Context
    \inmodule QtRos2
    \inheaderfile QtRos2Core/qros2context.h
    \brief Owns the process-wide ROS 2 context and the executor that spins it.

    Every ROS 2 entity in a process shares one context: rclcpp has to be
    initialized before any node is created, and something has to spin an
    executor for callbacks to arrive. QRos2Context is that singleton.

    QML applications do not normally touch it, because declaring a
    \l {QtRos2.Core::}{Node} initializes the context on demand. A C++
    application that creates entities before any QML is loaded, or that wants
    to pass ROS command-line arguments through, calls \l init() from \c main()
    first:

    \code
    int main(int argc, char *argv[])
    {
        QGuiApplication app(argc, argv);
        QRos2Context::init(argc, argv);
        ...
    }
    \endcode

    The context shuts down with the application.
*/

/*!
    \fn bool QRos2Context::isInitialized()
    Returns \c true if the ROS 2 context has been initialized.
*/

/*!
    \fn void QRos2Context::init()
    Initializes the ROS 2 context with no command-line arguments and a
    single-threaded executor.

    Does nothing if the context is already initialized, so it is safe to call
    from several places.
*/

/*!
    \fn void QRos2Context::init(int argc, char **argv, bool useMultithreadedExecutor, size_t threadCount)
    Initializes the ROS 2 context, passing \a argc and \a argv on to rclcpp so
    that ROS command-line arguments such as \c {--ros-args} are honoured.

    Pass \c true for \a useMultithreadedExecutor to spin callbacks on several
    threads, with \a threadCount threads; \c 0 lets rclcpp choose. Callbacks
    then run on executor threads rather than the Qt main thread, so anything
    they touch must be thread-safe.

    Does nothing if the context is already initialized.
*/

/*!
    \fn QRos2Context &QRos2Context::instance()
    Returns the singleton instance, initializing the context if it is not
    already initialized.
*/

/*!
    \fn const std::shared_ptr<rclcpp::Executor> &QRos2Context::executor() const
    Returns the executor spinning this context, for code that needs to add or
    remove nodes directly.
*/

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
