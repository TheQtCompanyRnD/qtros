# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

# Install the Python generator package and EmPy resource templates so the
# deployed rosidl_generator_qtros2Config.cmake can reference them via
# ${CMAKE_CURRENT_LIST_DIR} without source-tree paths.
qt_install(DIRECTORY
    "${CMAKE_SOURCE_DIR}/src/rosidl_generator_qtros2/rosidl_generator_qtros2"
    "${CMAKE_SOURCE_DIR}/src/rosidl_generator_qtros2/resource"
    DESTINATION "${QT_CONFIG_INSTALL_DIR}/Qt6Ros2Core"
    COMPONENT Devel
)

qt_internal_add_module(Ros2Core
    EXCEPTIONS
    SOURCES
        qros2node_p.h qros2node.cpp
        qros2nodechild_p.h qros2nodechild.cpp
        qros2entity_p.h qros2entity.cpp
        qros2parametervalue_p.h
        qros2parameter_p.h qros2parameter.cpp
        qros2remoteparameter_p.h qros2remoteparameter.cpp
        qros2publisherbase_p.h qros2publisherbase.cpp
        qros2stampedpublisherbase_p.h qros2stampedpublisherbase.cpp
        qros2subscriberbase_p.h qros2subscriberbase.cpp
        qros2serviceclientbase_p.h qros2serviceclientbase.cpp
        qros2serviceserverbase_p.h qros2serviceserverbase.cpp
        qros2actionclientbase_p.h qros2actionclientbase.cpp
        qros2actionserverbase_p.h qros2actionserverbase.cpp
        qros2qos_p.h qros2qos.cpp
        jsfuturewrapper_p.h jsfuturewrapper.cpp
        qros2context.h qros2context.cpp
        qros2contextitem_p.h qros2contextitem.cpp
    LIBRARIES
        Qt::Network
        Qt::Quick
        Qt::GuiPrivate
    PUBLIC_LIBRARIES
        Qt::Core
        Qt::Qml
        Qt::Concurrent
    EXTRA_CMAKE_INCLUDES
        QtRos2Macros.cmake
    EXTRA_CMAKE_FILES
        "${CMAKE_SOURCE_DIR}/cmake/QtRos2Macros.cmake"
        "${CMAKE_SOURCE_DIR}/cmake/rosidl_generator_qtros2Config.cmake"
        "${CMAKE_SOURCE_DIR}/src/rosidl_generator_qtros2/cmake/qtros2_generate_from_package.cmake"
        "${CMAKE_SOURCE_DIR}/src/rosidl_generator_qtros2/cmake/analyze_idl_dependencies.cmake"
        "${CMAKE_SOURCE_DIR}/src/rosidl_generator_qtros2/cmake/rosidl_generator_qtros2_generate_interfaces.cmake"
)

qt_internal_add_qml_module(Ros2Core
    URI "QtRos2.Core"
    VERSION "${PROJECT_VERSION}"
    DESIGNER_SUPPORTED
    DEPENDENCIES QtQuick/auto
    CLASS_NAME Ros2CorePlugin
    PLUGIN_TARGET ros2coreplugin
    NO_PLUGIN_OPTIONAL
)

# Link ROS2 libraries via plain CMake imported targets.
# find_package(rclcpp ...) etc. were already called by FindWrapRos2.cmake.
target_link_libraries(Ros2Core PUBLIC
    rclcpp::rclcpp
    rclcpp_action::rclcpp_action
    rosidl_runtime_cpp::rosidl_runtime_cpp
)

# Fast DDS network-interface re-scan (see qros2node.cpp): the participant is
# reached through rmw_fastrtps' introspection API. Optional: without it the
# bridge builds fine and Node.refreshNetworkInterfaces() becomes a no-op.
# rmw_fastrtps_cpp exports old-style ament variables, not imported targets.
find_package(rmw_fastrtps_cpp QUIET)
if(rmw_fastrtps_cpp_FOUND)
    target_link_libraries(Ros2Core PRIVATE ${rmw_fastrtps_cpp_LIBRARIES})
    target_include_directories(Ros2Core PRIVATE ${rmw_fastrtps_cpp_INCLUDE_DIRS})
    target_compile_definitions(Ros2Core PRIVATE QTROS2_HAVE_RMW_FASTRTPS)
endif()

qt_internal_add_docs(Ros2Core
    ../doc/qtros2.qdocconf
)
