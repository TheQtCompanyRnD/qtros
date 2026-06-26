
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
        "ControlPanel.qml"
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
find_package(qtros2_sensor_msgs REQUIRED)
find_package(qtros2_geometry_msgs REQUIRED)

qt_ros2_configure_target(Robot_{{ base_name }}
    CAPABILITIES SUBSCRIBER
    MODULES QtRos2SensorMessages QtRos2GeometryMessages
)

target_link_libraries(Robot_{{ base_name }} PUBLIC
    Qt6::Ros2Core
    qtros2_sensor_msgs::qtros2_sensor_msgs_qtcpp
    qtros2_geometry_msgs::qtros2_geometry_msgs_qtcpp
)
{% endif %}
{% if physics %}

# --- QtQuick3DPhysics dependency ---
find_package(Qt6 REQUIRED COMPONENTS Quick3DPhysics)
target_link_libraries(Robot_{{ base_name }} PUBLIC Qt6::Quick3DPhysics)
{% endif %}

set(ROBOT_{{ base_name }}_PLUGIN
    Robot_{{ base_name }}plugin
{% for p in plugins %}
    {{ p }}
{% endfor %}
    PARENT_SCOPE
)
