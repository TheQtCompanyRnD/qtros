cmake_minimum_required(VERSION 3.16)

project(simple_service_client VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Ros2Core)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appsimple_service_client
    main.cpp
)

qt_add_qml_module(appsimple_service_client
    URI simple_service_client
    QML_FILES
        Main.qml
)

qt_ros2_configure_target(appsimple_service_client
    CAPABILITIES SERVICE
    MODULES QtRos2StandardServices
)

set_target_properties(appsimple_service_client PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appsimple_service_client
    PRIVATE
        Qt6::Quick
)

include(GNUInstallDirs)
install(TARGETS appsimple_service_client
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
