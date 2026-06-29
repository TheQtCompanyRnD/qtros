cmake_minimum_required(VERSION 3.28)

project(r6botteachpendant VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick Quick3D Ros2Core)

qt_standard_project_setup()

# Main executable
qt_add_executable(r6botteachpendant
    main.cpp
)

file(GLOB_RECURSE LINK_QML_FILES_ABS "${CMAKE_CURRENT_SOURCE_DIR}/Link_*/*.qml")
file(GLOB_RECURSE LINK_MESH_FILES_ABS "${CMAKE_CURRENT_SOURCE_DIR}/Link_*/meshes/*.mesh")

# Mark Theme.qml as singleton
set_source_files_properties(Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(r6botteachpendant
    URI R6BotTeachPendant
    VERSION 1.0
    QML_FILES
        Main.qml
        R6BotViewModel.qml
        R6BotView3D.qml
        TFBufferManager.qml
        StatusBar.qml
        JogPanel.qml
        WaypointPanel.qml
        ReplayPanel.qml
        Theme.qml
        JointAxes.qml
        Link_0.qml
        Link_1.qml
        Link_2.qml
        Link_3.qml
        Link_4.qml
        Link_5.qml
        Link_6.qml
        R6BotModel.qml
    RESOURCES
        meshes/base_001_mesh.mesh
        meshes/link_2_mesh.mesh
        meshes/link_1_001_mesh.mesh
        meshes/link_3_001_mesh.mesh
        meshes/link_4_001_mesh.mesh
        meshes/link_5_001_mesh.mesh
        meshes/link_6_001_mesh.mesh
        jog.svg
        waypoint.svg
        play.svg
        qtquickcontrols2.conf
    RESOURCE_PREFIX /
    NO_RESOURCE_TARGET_PATH

)

# TF is consumed through QtRos2.Transforms (FrameTransformer), which wraps
# tf2_ros in C++, so no tf2_msgs QML module import is needed here.
qt_ros2_configure_target(r6botteachpendant
    CAPABILITIES PUBLISHER SUBSCRIBER
    MODULES QtRos2TrajectoryMessages
)

target_link_libraries(r6botteachpendant PRIVATE
    Qt6::Quick
    Qt6::Quick3D
)

install(TARGETS r6botteachpendant
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
