// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
#include <QGuiApplication>
#include <QQmlApplicationEngine>

#include <QtRos2Core/qros2context.h>

int main(int argc, char *argv[])
{
    QRos2Context::init(argc, argv);
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    engine.loadFromModule("R6BotTeachPendant", "Main");
    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
