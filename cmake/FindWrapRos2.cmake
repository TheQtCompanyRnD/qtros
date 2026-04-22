# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

# FindWrapRos2.cmake
#
# Locates a ROS 2 installation and sets up CMAKE_PREFIX_PATH so that
# downstream find_package() calls (ament_cmake, rclcpp, etc.) resolve correctly.
# NOTE: While this should work with different distros and installation paths,
#       it has only been tested against jazzy intalled at the default location (/opt/ros/)
#
# Input variables (in priority order):
#   ROS2_PATH              - CMake cache variable pointing to the ROS 2 install prefix
#   ENV{ROS2_PATH}         - Same, but as an environment variable
#   ENV{AMENT_PREFIX_PATH} - Set automatically when sourcing a ROS 2 setup.bash
#   ENV{ROS_DISTRO}        - Used to build the default path /opt/ros/<distro>
#
# Result targets:
#   WrapRos2::WrapRos2 - Interface target that propagates rclcpp, rclcpp_action,
#                        rosidl_runtime_cpp include dirs and link libraries.
#
# Result variables:
#   WrapRos2_FOUND
#   WrapRos2_PREFIX    - Resolved ROS 2 install prefix
#   WrapRos2_VERSION   - ROS 2 rclcpp version (if available)

if(TARGET WrapRos2::WrapRos2)
    set(WrapRos2_FOUND TRUE)
    # Still ensure rosidl_generator_qtros2_DIR is set even on re-entry.
    if(NOT rosidl_generator_qtros2_FOUND AND NOT DEFINED rosidl_generator_qtros2_DIR)
        set(_wrapros2_gen_dir "${CMAKE_CURRENT_LIST_DIR}/rosidl_generator_qtros2")
        if(NOT EXISTS "${_wrapros2_gen_dir}/rosidl_generator_qtros2Config.cmake")
            set(_wrapros2_gen_dir "${CMAKE_CURRENT_LIST_DIR}")
        endif()
        if(EXISTS "${_wrapros2_gen_dir}/rosidl_generator_qtros2Config.cmake")
            set(rosidl_generator_qtros2_DIR "${_wrapros2_gen_dir}"
                CACHE PATH "Path to rosidl_generator_qtros2 cmake directory" FORCE)
        endif()
        unset(_wrapros2_gen_dir)
    endif()
    return()
endif()

# Resolve the ROS 2 install prefix
if(NOT ROS2_PATH)
    if(NOT "$ENV{ROS2_PATH}" STREQUAL "")
        set(ROS2_PATH "$ENV{ROS2_PATH}" CACHE PATH "Path to the ROS 2 installation")
    elseif(NOT "$ENV{AMENT_PREFIX_PATH}" STREQUAL "")
        # AMENT_PREFIX_PATH is a colon-separated list; the ROS install root is last
        string(REPLACE ":" ";" _ros2_ament_prefix_list "$ENV{AMENT_PREFIX_PATH}")
        list(GET _ros2_ament_prefix_list -1 ROS2_PATH)
        set(ROS2_PATH "${ROS2_PATH}" CACHE PATH "Path to the ROS 2 installation")
        unset(_ros2_ament_prefix_list)
    elseif(NOT "$ENV{ROS_DISTRO}" STREQUAL "")
        set(ROS2_PATH "/opt/ros/$ENV{ROS_DISTRO}" CACHE PATH "Path to the ROS 2 installation")
    endif()
endif()

# Verify the path
set(__ros2_found FALSE)
if(ROS2_PATH AND EXISTS "${ROS2_PATH}/share/ament_cmake")
    set(WrapRos2_PREFIX "${ROS2_PATH}")
    set(__ros2_found TRUE)
endif()

# Extend CMAKE_PREFIX_PATH so find_package() works with the
if(__ros2_found)
    # Prepend so our ROS2 path takes precedence over any stale cache entries.
    list(PREPEND CMAKE_PREFIX_PATH "${WrapRos2_PREFIX}")

    # Set-up the AMENT_PREFIX_PATH in case the ROS 2 environment isn't set-up
    # through setup.bash etc., but provided by setting the ROS2_PATH explicitly.
    if("$ENV{AMENT_PREFIX_PATH}" STREQUAL "")
        set(ENV{AMENT_PREFIX_PATH} "${WrapRos2_PREFIX}")
    elseif(NOT "$ENV{AMENT_PREFIX_PATH}" MATCHES "(^|:)${WrapRos2_PREFIX}(:|$)")
        set(ENV{AMENT_PREFIX_PATH} "${WrapRos2_PREFIX}:$ENV{AMENT_PREFIX_PATH}")
	# Probably best we can do is print a warning here, because if we're injecting
	# another ROS path we're likely going to have some problems...
	message(WARNING "Adding path ${WrapRos2_PREFIX} to an existing AMENT_PREFIX_PATH.
	If multiple ROS distributions are set, then this might cause problems!")
    endif()

    # Some ROS 2 vendor packages (e.g. gz_math_vendor) live in subdirectories
    # in 'opt', e.g., /opt/ros/jazzy/opt/gz_math_vendor
    file(GLOB _ros2_vendor_prefixes "${WrapRos2_PREFIX}/opt/*")
    foreach(_vendor_prefix ${_ros2_vendor_prefixes})
        if(IS_DIRECTORY "${_vendor_prefix}")
            list(APPEND CMAKE_PREFIX_PATH "${_vendor_prefix}")
	    message(STATUS "FindWrapRos2: Added vendor package ${_vendor_prefix} to CMAKE_PREFIX_PATH")
        endif()
    endforeach()
    unset(_ros2_vendor_prefixes)
    unset(_vendor_prefix)

    # Extend PYTHONPATH so that execute_process() calls made by ament_cmake's
    # configure-time Python scripts (e.g. templates_2_cmake.py which imports
    # ament_package) can find the ROS 2 Python site-packages.
    file(GLOB _ros2_python_site_packages "${WrapRos2_PREFIX}/lib/python*/site-packages")
    if(_ros2_python_site_packages)
        # Prepend to PYTHONPATH; preserve any existing value.
        if(NOT "$ENV{PYTHONPATH}" STREQUAL "")
            set(ENV{PYTHONPATH} "${_ros2_python_site_packages}:$ENV{PYTHONPATH}")
        else()
            set(ENV{PYTHONPATH} "${_ros2_python_site_packages}")
        endif()
        message(STATUS "FindWrapRos2: extended PYTHONPATH with ${_ros2_python_site_packages}")
    endif()
    unset(_ros2_python_site_packages)

    # Find the required ROS 2 packages now that the prefix path is set.
    find_package(ament_cmake QUIET)
    find_package(rclcpp QUIET)
    find_package(rclcpp_action QUIET)
    find_package(rosidl_runtime_cpp QUIET)
    find_package(rmw QUIET)

    if(rclcpp_FOUND AND rclcpp_action_FOUND AND rosidl_runtime_cpp_FOUND)
        set(__ros2_packages_found TRUE)
        if(rclcpp_VERSION)
            set(WrapRos2_VERSION "${rclcpp_VERSION}")
        endif()
    else()
        set(__ros2_packages_found FALSE)
        message(WARNING
            "FindWrapRos2: ROS 2 prefix found at '${WrapRos2_PREFIX}' but required "
            "packages are missing (rclcpp=${rclcpp_FOUND}, "
            "rclcpp_action=${rclcpp_action_FOUND}, "
            "rosidl_runtime_cpp=${rosidl_runtime_cpp_FOUND}).")
    endif()
else()
    set(__ros2_packages_found FALSE)
    message(FATAL_ERROR "No ROS 2 installtion found! - "
	                "Make sure your \'ROS2_PATH\' is pointing to a valid ROS 2 installation!")
endif()

# Report status
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(WrapRos2
    REQUIRED_VARS __ros2_found __ros2_packages_found WrapRos2_PREFIX
    VERSION_VAR WrapRos2_VERSION
)

# Create the imported target
if(WrapRos2_FOUND)
    add_library(WrapRos2::WrapRos2 INTERFACE IMPORTED)
    target_link_libraries(WrapRos2::WrapRos2
        INTERFACE
            rclcpp::rclcpp
            rclcpp_action::rclcpp_action
            rosidl_runtime_cpp::rosidl_runtime_cpp
    )
    if(TARGET rmw::rmw)
        target_link_libraries(WrapRos2::WrapRos2 INTERFACE rmw::rmw)
    endif()

    # Make rosidl_generator_qtros2 cmake helpers findable without an explicit DIR hint.
    # The cmake files are installed alongside this file in the Qt6Ros2Core cmake dir.
    if(NOT rosidl_generator_qtros2_FOUND AND NOT DEFINED rosidl_generator_qtros2_DIR)
        # Check subdirectory first (preferred layout), then same directory as fallback.
        set(_wrapros2_gen_dir "${CMAKE_CURRENT_LIST_DIR}/rosidl_generator_qtros2")
        if(NOT EXISTS "${_wrapros2_gen_dir}/rosidl_generator_qtros2Config.cmake")
            set(_wrapros2_gen_dir "${CMAKE_CURRENT_LIST_DIR}")
        endif()
        if(EXISTS "${_wrapros2_gen_dir}/rosidl_generator_qtros2Config.cmake")
            set(rosidl_generator_qtros2_DIR "${_wrapros2_gen_dir}"
                CACHE PATH "Path to rosidl_generator_qtros2 cmake directory" FORCE)
        endif()
        unset(_wrapros2_gen_dir)
    endif()
endif()

unset(__ros2_found)
unset(__ros2_packages_found)
