// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: BSD-3-Clause

#include <QtRos2Core/qros2context.h>

#include <QtCore/qcoreapplication.h>
#include <QtCore/qprocess.h>
#include <QtTest/qtest.h>

#include <csignal>
#include <cstdio>
#include <cstring>
#include <sys/types.h>

static constexpr char kHelperArg[] = "--ros2-helper";
static constexpr char kReadyToken[] = "QTROS2_HELPER_READY";

// Child mode: a minimal QtRos2 app, like the examples or a headless dogzillad.
// It brings up a real rclcpp context + DDS participant and runs the Qt event
// loop. With QRos2Context's on_shutdown -> quit() wiring, a delivered SIGTERM
// must make exec() return so the participant tears down cleanly. The signal is
// raised by the parent, not here, and this is a plain QCoreApplication (not a
// QTest process), so QtTest's fatal-signal handler is not in the way.
static int runHelper(int argc, char **argv)
{
    QCoreApplication app(argc, argv);
    QRos2Context::init();
    // Announce readiness only after rclcpp::init() has installed its signal
    // handler, so the parent can't signal during the default-terminate window.
    std::puts(kReadyToken);
    std::fflush(stdout);
    return app.exec();
}

class tst_shutdown : public QObject
{
    Q_OBJECT
private slots:
    void exitsCleanlyOnTermSignal();
};

// Regression test for the FastDDS shared-memory "second process hangs" bug.
// rclcpp's SIGINT/SIGTERM handler calls rclcpp::shutdown() but does not stop the
// Qt event loop, so without the on_shutdown -> quit() wiring a QtRos2 app could
// only be SIGKILL'd -- which skips destructors and leaks the participant's
// shared-memory port lock (/dev/shm/sem.fastrtps_port*_mutex), deadlocking the
// next process to start. Launch a real QtRos2 child, send it SIGTERM, and require
// it to exit on its own (the pre-fix behaviour was to hang until SIGKILL).
void tst_shutdown::exitsCleanlyOnTermSignal()
{
    QProcess helper;
    helper.setProcessChannelMode(QProcess::MergedChannels);
    helper.setProgram(QCoreApplication::applicationFilePath());
    helper.setArguments({ QString::fromLatin1(kHelperArg) });
    helper.start();
    QVERIFY2(helper.waitForStarted(), "helper process failed to start");

    // Wait until the child reports it has finished rclcpp::init() before signalling.
    QByteArray out;
    const bool ready = QTest::qWaitFor([&] {
        helper.waitForReadyRead(100);
        out += helper.readAll();
        return out.contains(kReadyToken);
    }, 15000);
    QVERIFY2(ready, "helper never reported readiness");

    QCOMPARE(::kill(static_cast<pid_t>(helper.processId()), SIGTERM), 0);

    QVERIFY2(helper.waitForFinished(10000),
             "QtRos2 app did not exit on SIGTERM (regressed: requires SIGKILL, leaks SHM lock)");
    QCOMPARE(helper.exitStatus(), QProcess::NormalExit);
    QCOMPARE(helper.exitCode(), 0);
}

int main(int argc, char **argv)
{
    for (int i = 1; i < argc; ++i) {
        if (std::strcmp(argv[i], kHelperArg) == 0)
            return runHelper(argc, argv);
    }
    QCoreApplication app(argc, argv);
    tst_shutdown tc;
    return QTest::qExec(&tc, argc, argv);
}

#include "tst_shutdown.moc"
