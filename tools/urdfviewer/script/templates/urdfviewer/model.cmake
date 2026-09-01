
cmake_minimum_required(VERSION 3.19)
project(Robot_{{ base_name }} LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Quick3D)

qt_add_executable(Robot_{{ base_name }}
    main.cpp
)

qt_add_qml_module(Robot_{{ base_name }}
    URI {{ base_name }}
    VERSION 1.0
    QML_FILES
{% if main_qml %}
        "Main.qml"
{% endif %}
        "{{ base_name }}.qml"
{% if preview_scene %}
{% if not ros_bridge %}
        "ControlPanel.qml"
{% endif %}
        "PreviewScene.qml"
{% endif %}
{% if ros_bridge %}
        "RosBridge.qml"
{% endif %}
    SOURCES
        "{{ base_name }}ControlBase.h"
        "{{ base_name }}ControlBase.cpp"
        "{{ base_name }}Control.h"
        "{{ base_name }}Control.cpp"
    RESOURCES
        "{{ joints_name }}_joints.json"
)

set_target_properties(Robot_{{ base_name }} PROPERTIES
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE TRUE
)

target_link_libraries(Robot_{{ base_name }} PUBLIC Qt6::Quick3D)
{% if plugins %}
add_subdirectory(Generated)
{% endif %}
{% if ros_bridge %}

# --- ROS Bridge dependencies (requires Qt ROS2 bridge installed) ---
find_package(Qt6 REQUIRED COMPONENTS Ros2Core)

# qt_ros2_configure_target() finds the requested QtRos2* message modules and
# links them, together with Qt6::Ros2Core, into the target.
qt_ros2_configure_target(Robot_{{ base_name }}
    CAPABILITIES SUBSCRIBER
    MODULES QtRos2SensorMessages QtRos2GeometryMessages
)
{% endif %}
{% if physics %}

# --- QtQuick3DPhysics dependency ---
find_package(Qt6 REQUIRED COMPONENTS Quick3DPhysics)
target_link_libraries(Robot_{{ base_name }} PUBLIC Qt6::Quick3DPhysics)
{% endif %}

# Export the QML plugin list when this project is pulled in via add_subdirectory().
# Skipped for a standalone build, where there is no parent scope to set.
if(NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    set(ROBOT_{{ base_name }}_PLUGIN
        Robot_{{ base_name }}plugin
{% for p in plugins %}
        {{ p }}
{% endfor %}
        PARENT_SCOPE
    )
endif()
