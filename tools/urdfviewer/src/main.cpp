// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only WITH Qt-GPL-exception-1.0
#include "ImporterWindow.h"

#include <QApplication>
#include <QCommandLineParser>

#ifndef NO_URDF_IMPORTER_ROS_BRIDGE
#include <QtRos2Core/qros2context.h>
#endif

int main(int argc, char *argv[])
{
#ifndef NO_URDF_IMPORTER_ROS_BRIDGE
    QRos2Context::init(argc, argv);
#endif

    QApplication app(argc, argv);
    QCommandLineParser parser;
    parser.setApplicationDescription(QCoreApplication::translate("main",
        "Import a URDF file, preview and export a Qt Quick 3D scene"));
    parser.addHelpOption();
    parser.addVersionOption();
    QCommandLineOption bridgeOption(QStringList() << "b" << "bridge",
            QCoreApplication::translate("main", "Preview with live ROS bridge."));
    parser.addOption(bridgeOption);
    QCommandLineOption upmOption(QStringList() << "u" << "upm",
            QCoreApplication::translate("main", "Scene <units> per meter."),
            QCoreApplication::translate("main", "units"));
    parser.addOption(upmOption);
    QCommandLineOption pfxOption(QStringList() << "p" << "topic-prefix",
            QCoreApplication::translate("main", "DDS topic <prefix> for robot."),
            QCoreApplication::translate("main", "prefix"));
    parser.addOption(pfxOption);
    parser.addPositionalArgument("urdf or xacro", QCoreApplication::translate("main", "File to open"));
    parser.addPositionalArgument("destination", QCoreApplication::translate("main", "Output directory"));
    parser.process(app);

    ImporterWindow window;
    window.setRosBridge(parser.isSet(bridgeOption));
    if (parser.isSet(upmOption)){
        auto s = parser.value(upmOption);
        bool ok = false;
        double v = s.toDouble(&ok);
        if (ok)
            window.setUnitsPerMeter(v);
    }
    if (parser.isSet(pfxOption))
        window.setTopicPrefix(parser.value(pfxOption));
    const QStringList args = parser.positionalArguments();
    if (args.size() > 0)
        window.setUrdfPath(args.at(0));
    if (args.size() > 1)
        window.setOutputPath(args.at(1));

    window.resize(1600, 900);
    window.show();

    return app.exec();
}
