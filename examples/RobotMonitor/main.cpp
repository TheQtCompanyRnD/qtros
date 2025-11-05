#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <qtros2_core/qros2_context.hpp>

int main(int argc, char *argv[])
{
    QROS2Context::init(argc, argv);
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("RobotMonitor", "Main");

    return app.exec();
}
