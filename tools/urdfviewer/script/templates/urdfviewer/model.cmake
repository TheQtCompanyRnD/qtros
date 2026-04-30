
qt_add_library(Robot_{{ base_name }} STATIC)
qt_add_qml_module(Robot_{{ base_name }}
    URI "{{ base_name }}"
    VERSION 1.0
    RESOURCE_PREFIX "/qt/qml"
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
    QML_FILES
        "{{ base_name }}.qml"
{% if ros_bridge %}
        "RosPreviewScene.qml"
        "RosMain.qml"
{% endif %}
    SOURCES
        "{{ base_name }}ControlBase.h"
        "{{ base_name }}ControlBase.cpp"
        "{{ base_name }}Control.h"
        "{{ base_name }}Control.cpp"
    RESOURCES
        "{{ joints_name }}_joints.json"
)

target_link_libraries(Robot_{{ base_name }} PUBLIC Qt6::Gui)
{% if plugins %}
add_subdirectory(Generated)
{% endif %}
{% if ros_bridge %}

# --- ROS Bridge dependencies (requires Qt ROS2 bridge installed) ---
find_package(Qt6 REQUIRED COMPONENTS Ros2Core)
find_package(qtros2_sensor_msgs REQUIRED)

qt_ros2_configure_target(Robot_{{ base_name }}
    CAPABILITIES SUBSCRIBER
    MODULES QtRos2SensorMessages
)

target_link_libraries(Robot_{{ base_name }} PUBLIC
    Qt6::Ros2Core
    qtros2_sensor_msgs::qtros2_sensor_msgs_qtcpp
)
{% endif %}

set(ROBOT_{{ base_name }}_PLUGIN
    Robot_{{ base_name }}plugin
{% for p in plugins %}
    {{ p }}
{% endfor %}
    PARENT_SCOPE
)
