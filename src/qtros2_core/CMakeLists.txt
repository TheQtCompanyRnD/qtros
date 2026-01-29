# Copyright (C) 2022 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

cmake_minimum_required(VERSION 3.16)
project(qtros2_core)

# Compiler settings
if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 17)
endif()

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# Find dependencies
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rclcpp_action REQUIRED)
find_package(rmw REQUIRED)
find_package(rosidl_runtime_cpp REQUIRED)

# Find Qt6
find_package(Qt6 REQUIRED COMPONENTS Core Qml Quick Concurrent)

# Detect QoS "best available" support (added in newer ROS 2)
include(CheckCXXSourceCompiles)
set(_qtros2_core_required_includes "${CMAKE_REQUIRED_INCLUDES}")
set(CMAKE_REQUIRED_INCLUDES ${rmw_INCLUDE_DIRS})
check_cxx_source_compiles("
#include <rmw/types.h>
int main() {
  rmw_qos_reliability_policy_t policy = RMW_QOS_POLICY_RELIABILITY_BEST_AVAILABLE;
  (void)policy;
  return 0;
}
" QTROS2_HAS_RMW_QOS_RELIABILITY_BEST_AVAILABLE)
check_cxx_source_compiles("
#include <rmw/types.h>
int main() {
  rmw_qos_durability_policy_t policy = RMW_QOS_POLICY_DURABILITY_BEST_AVAILABLE;
  (void)policy;
  return 0;
}
" QTROS2_HAS_RMW_QOS_DURABILITY_BEST_AVAILABLE)
set(CMAKE_REQUIRED_INCLUDES "${_qtros2_core_required_includes}")

# Enable Qt MOC, RCC, UIC
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Create library with Qt6 QML module (this enables auto-registration!)
qt_add_library(qtros2_core SHARED)

qt_policy(SET QTP0001 NEW)

qt_add_qml_module(qtros2_core
    URI QtROS2.Core
    VERSION 1.0
    SOURCES
        src/qros2_node.cpp
        src/qros2_entity.cpp
        src/qros2_publisher_base.cpp
        src/qros2_subscriber_base.cpp
        src/qros2_service_client_base.cpp
        src/qros2_action_client_base.cpp
        src/qros2_qos.cpp
        include/qtros2_core/qros2_node.hpp
        include/qtros2_core/qros2_entity.hpp
        include/qtros2_core/qros2_publisher_base.hpp
        include/qtros2_core/qros2_subscriber_base.hpp
        include/qtros2_core/qros2_service_client_base.hpp
        include/qtros2_core/qros2_action_client_base.hpp
        include/qtros2_core/qros2_qos.hpp
        include/qtros2_core/qros2_context.hpp
        src/js_future_wrapper.cpp
        include/qtros2_core/js_future_wrapper.hpp
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml/QtROS2/Core
)

# Add metatypes JSON as INTERFACE_SOURCES so dependent modules can find it
# Qt's qt_add_qml_module uses this to automatically collect foreign types
# Use BUILD_INTERFACE for build tree and INSTALL_INTERFACE for installed tree
get_target_property(_qtros2_core_metatypes_file qtros2_core INTERFACE_QT_META_TYPES_BUILD_FILE)
get_target_property(_qtros2_core_metatypes_name qtros2_core INTERFACE_QT_META_TYPES_FILE_NAME)

if(_qtros2_core_metatypes_file)
    set(_qtros2_core_consumes_metatypes "$<BOOL:$<TARGET_PROPERTY:QT_CONSUMES_METATYPES>>")
    set(_qtros2_core_metatypes_build "$<BUILD_INTERFACE:$<${_qtros2_core_consumes_metatypes}:${_qtros2_core_metatypes_file}>>")
    set(_qtros2_core_metatypes_install "$<INSTALL_INTERFACE:$<${_qtros2_core_consumes_metatypes}:$<INSTALL_PREFIX>/lib/metatypes/${_qtros2_core_metatypes_name}>>")
    target_sources(qtros2_core INTERFACE ${_qtros2_core_metatypes_build} ${_qtros2_core_metatypes_install})
endif()

# Include directories - make headers available from src/
target_include_directories(qtros2_core PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include/qtros2_core>
    $<INSTALL_INTERFACE:include>
)

target_compile_definitions(qtros2_core PUBLIC
    $<$<BOOL:${QTROS2_HAS_RMW_QOS_RELIABILITY_BEST_AVAILABLE}>:QTROS2_HAS_RMW_QOS_RELIABILITY_BEST_AVAILABLE>
    $<$<BOOL:${QTROS2_HAS_RMW_QOS_DURABILITY_BEST_AVAILABLE}>:QTROS2_HAS_RMW_QOS_DURABILITY_BEST_AVAILABLE>
)

# Link Qt libraries
target_link_libraries(qtros2_core PUBLIC
    Qt6::Core
    Qt6::Qml
    Qt6::Concurrent
)

target_link_libraries(qtros2_core PRIVATE
    Qt6::Quick
)

# Link ROS2 libraries
ament_target_dependencies(qtros2_core PUBLIC
    rclcpp
    rclcpp_action
    rmw
    rosidl_runtime_cpp
)

# Install library
install(TARGETS qtros2_core
    EXPORT qtros2_coreTargets
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)

# Install QML module files
install(DIRECTORY ${CMAKE_BINARY_DIR}/qml/QtROS2
    DESTINATION lib/qt6/qml
)

# Install metatypes JSON for dependent modules
get_target_property(_qtros2_core_metatypes_install_file qtros2_core INTERFACE_QT_META_TYPES_BUILD_FILE)
if(_qtros2_core_metatypes_install_file AND EXISTS "${_qtros2_core_metatypes_install_file}")
    install(FILES "${_qtros2_core_metatypes_install_file}"
        DESTINATION lib/metatypes
    )
endif()


# Ensure QML import path is exposed when sourcing this package
set(_qtros2_core_env_hooks
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/environment_hooks/qtros2_core_qml_import_path.sh"
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/environment_hooks/qtros2_core_qml_import_path.dsv"
)
ament_environment_hooks(${_qtros2_core_env_hooks})

# Install headers
install(DIRECTORY include/
    DESTINATION include
)

# Export targets
ament_export_targets(qtros2_coreTargets HAS_LIBRARY_TARGET)
ament_export_dependencies(
    rclcpp
    rclcpp_action
    rmw
    rosidl_runtime_cpp
    Qt6Core
    Qt6Qml
    Qt6Concurrent
)

if(BUILD_TESTING)
    find_package(ament_lint_auto REQUIRED)
    ament_lint_auto_find_test_dependencies()
endif()

ament_package()
