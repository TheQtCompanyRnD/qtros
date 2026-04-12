#include <QGuiApplication>
#include <QQmlApplicationEngine>

#include <QtRos2Core/qros2context.h>

int main(int argc, char *argv[])
{
    QRos2Context::init(argc, argv);
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("simple_subscriber", "Main");

    return app.exec();
}
