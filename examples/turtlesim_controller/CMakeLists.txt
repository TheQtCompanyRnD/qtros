cmake_minimum_required(VERSION 3.16)

project(turtlesim_controller VERSION 0.1 LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Ros2Core)

qt_add_executable(appturtlesim_controller
    main.cpp
)

qt_add_qml_module(appturtlesim_controller
    URI TurtleSimController
    VERSION 1.0
    QML_FILES
        Main.qml
        TurtleControllerNode.qml
)

qt_ros2_configure_target(appturtlesim_controller
    CAPABILITIES PUBLISHER SUBSCRIBER SERVICE ACTION
    MODULES QtRos2GeometryMessages
    IMPORT_PACKAGES turtlesim
)

target_link_libraries(appturtlesim_controller
    PUBLIC
        Qt::Quick
)
