#include <QGuiApplication>
#include <QQmlApplicationEngine>

#include <qtros2_core/qros2_context.hpp>

int main(int argc, char *argv[])
{
    QROS2Context::init(argc, argv);
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    engine.loadFromModule("R6BotTeachPendant", "Main");
    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
