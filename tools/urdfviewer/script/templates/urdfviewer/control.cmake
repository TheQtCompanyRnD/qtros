
find_package(Qt6 REQUIRED COMPONENTS Gui)

qt_add_library(RobotControl_{{ base_name }} STATIC)
qt6_add_qml_module(RobotControl_{{ base_name }}
    URI "RobotControl.{{ base_name }}"
    VERSION 1.0
    RESOURCE_PREFIX "/qt/qml"
    SOURCES
        "{{ base_name }}ControlBase.h"
        "{{ base_name }}ControlBase.cpp"
        "{{ base_name }}Control.h"
        "{{ base_name }}Control.cpp"
    RESOURCES
        "{{ joints_name }}_joints.json"
)

target_link_libraries(RobotControl_{{ base_name }} PUBLIC Qt6::Gui)

set(ROBOT_{{ base_name }}_CONTROL_PLUGIN
    RobotControl_{{ base_name }}plugin
    PARENT_SCOPE
)
