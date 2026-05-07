// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: BSD-3-Clause

#include <QGuiApplication>
#include <QQmlApplicationEngine>

#include <QtQuick3D/qquick3d.h>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QSurfaceFormat::setDefaultFormat(QQuick3D::idealSurfaceFormat());

    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/qt/qml/io/qt/tests/manual/urdfrobotarm/Main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
