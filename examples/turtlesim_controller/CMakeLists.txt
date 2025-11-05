cmake_minimum_required(VERSION 3.16)

project(turtlesim_controller VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)
find_package(rosidl_generator_qtros2 REQUIRED)
find_package(qtros2_geometry_msgs REQUIRED)

qt_standard_project_setup(REQUIRES 6.8)

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

qtros2_generate_from_package(
    TARGET turtlesim_wrapper
    SOURCE_PACKAGE turtlesim
    QML_MODULE_URI TurtleSimMsgs
    QML_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/TurtleSimMsgs
)

target_link_libraries(appturtlesim_controller
    PRIVATE
        Qt6::Quick
        qtros2_geometry_msgs::qtros2_geometry_msgs_qtcpp
        turtlesim_wrapper_qtcpp
)
