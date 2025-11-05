cmake_minimum_required(VERSION 3.16)

project(simple_subscriber VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)
find_package(qtros2_geometry_msgs REQUIRED)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appsimple_subscriber
    main.cpp
)

qt_add_qml_module(appsimple_subscriber
    URI simple_subscriber
    QML_FILES
        Main.qml
)

set_target_properties(appsimple_subscriber PROPERTIES
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appsimple_subscriber
    PRIVATE
        Qt6::Quick
        qtros2_geometry_msgs::qtros2_geometry_msgs_qtcpp
)

include(GNUInstallDirs)
install(TARGETS appsimple_subscriber
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
