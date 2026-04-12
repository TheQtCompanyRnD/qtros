// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2contextitem_p.h"
#include "qros2context.h"

#include <QDebug>

QT_BEGIN_NAMESPACE

/*!
    \qmltype Ros2Context
    \inqmlmodule QtRos2.Core
    \brief Configures and initialises the ROS 2 context for a QML application.

    Ros2Context provides a declarative way to initialise the underlying
    \c rclcpp context from QML, removing the need for a C++ entry point to
    call \c QRos2Context::init().

    If no Ros2Context item is present, the first \l Ros2Node that is created
    will auto-initialise the context with default settings (no extra ROS args,
    and a threaded executor). Use Ros2Context when you need explicit control
    over these options. Or use the \l {QRos2Context} type from C++ for even
    more fine-grained controll.

    \note Only one Ros2Context should exist per application. Subsequent
    instances are silently ignored. The same is true if QRos2Context::init()
    is called prior to any Ros2Context being created.

    \note Property values once and are suggestive. The ROS context might decide
          to ignore them.

    \qml
    import QtRos2.Core

    Ros2Context {
        // Remap the joint_states topic for a namespaced robot:
        nodeArgs: ["--ros-args", "--remap", "/joint_states:=/my_robot/joint_states"]
        multithreaded: false
    }
    \endqml

    Place Ros2Context \e before any \l Ros2Node item in the same component so
    that the context is ready before nodes are created.
*/

/*!
    \qmlproperty list<string> Ros2Context::nodeArgs

    Additional command-line arguments forwarded to \c rclcpp::init(), e.g.
    \c ["--ros-args", "--remap", "/joint_states:=/robot/joint_states"].
    Must be set before the component completes and can only be set once.
*/

/*!
    \qmlproperty bool Ros2Context::multithreaded

    When \c true, a \c MultiThreadedExecutor is used instead of the default
    \c SingleThreadedExecutor.  Defaults to \c true.
*/

/*!
    \qmlproperty int Ros2Context::threadCount

    Number of threads for the multi-threaded executor.  \c 0 means
    hardware-concurrency.  Ignored when \l multithreaded is \c false.
*/

QRos2ContextItem::QRos2ContextItem(QObject *parent)
    : QObject(parent)
{
}

QRos2ContextItem::~QRos2ContextItem()
{

}

void QRos2ContextItem::setNodeArgs(const QStringList &args)
{
    if (m_initialized)
        return;

    if (m_nodeArgs == args)
        return;
    m_nodeArgs = args;
    emit nodeArgsChanged();
}

void QRos2ContextItem::setMultithreaded(bool mt)
{
    if (m_initialized)
        return;

    if (m_multithreaded == mt)
        return;
    m_multithreaded = mt;
    emit multithreadedChanged();
}

void QRos2ContextItem::setThreadCount(int n)
{
    if (m_initialized)
        return;

    if (m_threadCount == n)
        return;
    m_threadCount = n;
    emit threadCountChanged();
}

void QRos2ContextItem::classBegin()
{

}

void QRos2ContextItem::componentComplete()
{
    m_initialized = QRos2Context::isInitialized();

    if (m_initialized) {
        qWarning() << "Ros2Context: ROS 2 context is already initialised "
                      "(auto-init fired before Ros2Context completed, or a "
                      "duplicate Ros2Context exists). nodeArgs will be ignored.";
        // FIXME: Would be nice if we could update the properties here to reflect what
        //        is the state of the ros2context...
        return;
    }


    QRos2Context::initFromContextItem(m_nodeArgs, m_multithreaded,
                                      static_cast<size_t>(m_threadCount));
    m_initialized = QRos2Context::isInitialized();
}

QT_END_NAMESPACE
