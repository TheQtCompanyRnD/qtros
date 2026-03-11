cmake_minimum_required(VERSION 3.16)

project(RobotMonitor VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Quick3D)
find_package(Qt6 REQUIRED COMPONENTS Quick)
find_package(qtros2_core REQUIRED)
find_package(qtros2_nav_msgs)
find_package(rosidl_generator_qtros2 REQUIRED)
find_package(qtros2_geometry_msgs REQUIRED)
find_package(qtros2_sensor_msgs REQUIRED)


qt_standard_project_setup(REQUIRES 6.8)


qtros2_generate_from_package(
    TARGET qtros2_tf2_msgs
    SOURCE_PACKAGE tf2_msgs
    QML_MODULE_URI QtRos2.Tf2Msgs
    QML_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/QtRos2/Tf2Msgs
)

qtros2_generate_from_package(
   TARGET qtros2_geographic_msgs
   SOURCE_PACKAGE geographic_msgs
   QML_MODULE_URI GeographicMsgs
   QML_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/GeographicMsgs
)

qtros2_generate_from_package(
    TARGET qtros2_nav2_msgs
    SOURCE_PACKAGE nav2_msgs
    QML_MODULE_URI Nav2Msgs
    QML_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/Nav2Msgs
    DEPENDS qtros2_geographic_msgs
)

qtros2_generate_from_package(
    TARGET qtros2_irobot_create_msgs
    SOURCE_PACKAGE irobot_create_msgs
    QML_MODULE_URI IRobotCreateMsgs
    QML_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/IRobotCreateMsgs
)

qt_add_executable(appRobotMonitor
    main.cpp
)

set_source_files_properties(GeometryHeleper.qml Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(appRobotMonitor
    URI RobotMonitor
    VERSION 1.0
    QML_FILES
        Main.qml
        MainViewModel.qml
        TFManager.qml
        MapVisualSettings.qml
        OccupancyGrid.qml
        GeometryHeleper.qml
        LaserScan.qml
        ShapeData.qml
        ShapeNode.qml
        GridNode.qml
        VideoView.qml
        ExpandablePanel.qml
        Theme.qml
        SceneView.qml
        SidePanel.qml
        DrivePanel.qml
        LayersPanel.qml
        StyledButton.qml
        StatusRow.qml
        StyledCheckBox.qml
        StyledSlider.qml
        VisualSettings.qml
        GridVisualSettings.qml
        LaserScanVisualSettings.qml
        ColorSettingsEntry.qml
        SchemeSelector.qml
        GridPalette.qml
    RESOURCES
        shaders/IndexedGrid.frag
        shaders/IndexedGrid.vert
        images/arrow.svg
        images/triangle.svg
        images/draghandle.svg
        images/gear.svg
        images/robot.svg
    SOURCES
        rosimageitem.h rosimageitem.cpp
        QML_FILES
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appRobotMonitor PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appRobotMonitor
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appRobotMonitor
    PRIVATE
    Qt6::Quick
    Qt6::Quick3D
    qtros2_core::qtros2_core
    qtros2_nav_msgs::qtros2_nav_msgs_qtcpp
    qtros2_geometry_msgs::qtros2_geometry_msgs_qtcpp
    qtros2_sensor_msgs::qtros2_sensor_msgs_qtcpp
    qtros2_tf2_msgs_qtcpp
    qtros2_nav2_msgs_qtcpp
    qtros2_irobot_create_msgs_qtcpp
)

include(GNUInstallDirs)
install(TARGETS appRobotMonitor
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
