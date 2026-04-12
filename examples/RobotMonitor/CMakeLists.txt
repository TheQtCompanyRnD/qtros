cmake_minimum_required(VERSION 3.16)

project(RobotMonitor VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Quick3D Ros2Core)

qt_standard_project_setup(REQUIRES 6.8)

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
        Nav2IrobotActions.qml
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

# Collect optional IMPORT_PACKAGES — only include those present in the ROS distro
set(_optional_import_packages "")
find_package(tf2_msgs QUIET)
if(tf2_msgs_FOUND)
    list(APPEND _optional_import_packages tf2_msgs)
endif()
find_package(geographic_msgs QUIET)
find_package(nav2_msgs QUIET)
if(geographic_msgs_FOUND AND nav2_msgs_FOUND)
    list(APPEND _optional_import_packages geographic_msgs nav2_msgs)
endif()
find_package(irobot_create_msgs QUIET)
if(irobot_create_msgs_FOUND)
    list(APPEND _optional_import_packages irobot_create_msgs)
endif()

qt_ros2_configure_target(appRobotMonitor
    CAPABILITIES PUBLISHER SUBSCRIBER ACTION
    MODULES
        QtRos2NavigationMessages
        QtRos2GeometryMessages
        QtRos2SensorMessages
    IMPORT_PACKAGES ${_optional_import_packages}
)

set_target_properties(appRobotMonitor PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appRobotMonitor
    PRIVATE
        Qt6::Quick
        Qt6::Quick3D
)

include(GNUInstallDirs)
install(TARGETS appRobotMonitor
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
