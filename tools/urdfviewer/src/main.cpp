#include "ImporterWindow.h"

#include <QApplication>

#ifndef NO_URDF_IMPORTER_ROS_BRIDGE
#include <QtRos2Core/qros2context.h>
#endif

int main(int argc, char *argv[])
{
#ifndef NO_URDF_IMPORTER_ROS_BRIDGE
    QRos2Context::init(argc, argv);
#endif

    QApplication app(argc, argv);

    ImporterWindow window;
    window.resize(1600, 900);
    window.show();

    return app.exec();
}
