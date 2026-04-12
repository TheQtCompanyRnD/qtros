# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

# Simplified helper for configuring a target with QtROS2 support.
#
# Usage:
#   qt_ros2_configure_target(<target>
#     CAPABILITIES <MESSAGES|PUBLISHER|SUBSCRIBER|SERVICE|ACTION> [<CAP2> ...]
#     [MODULES <QtRos2Module> ...]
#     [IMPORT_PACKAGES <ros2_package> ...]
#   )
#
# CAPABILITIES describes which ROS2 communication patterns the target uses (informational;
# used for validation). Multiple values may be specified.
#
# MODULES lists pre-built Qt module names (e.g. QtRos2GeometryMessages) to link against.
#
# IMPORT_PACKAGES lists external ROS2 package names (e.g. turtlesim) for which Qt/QML type
# wrappers will be generated and linked automatically. The generated QML module URI will be
# "QtRos2.Imported.<CamelCase>" (e.g. "QtRos2.Imported.Turtlesim"), and the generated target
# is linked to <target> implicitly.
#
# The function also ensures that rosidl_generator_qtros2 cmake helpers are available so
# the caller can subsequently use qtros2_generate_from_package().

# Register pre-built Qt ROS2 modules in the QTROS2_SOURCE_PKG_<pkg> global property
# registry so that qtros2_generate_from_package() can resolve IDL-level dependencies.
#
# Every pre-built Qt ROS2 module links publicly against exactly one target of the form
# <pkg>::<pkg>__rosidl_typesupport_cpp (this is set by qtros2_generate_from_package()
# during the module's own build and exported via INTERFACE_LINK_LIBRARIES).  Extracting
# the package name from that entry avoids any hardcoded mapping table.
#
# Usage:
#   _qtros2_register_prebuilt_modules(<comp1> [<comp2> ...])
#
# Each argument is a Qt6 component name (without the "Qt6::" prefix), e.g.
# QtRos2GeometryMessages.  Only targets that are already imported are processed.
function(_qtros2_register_prebuilt_modules)
  foreach(_qtros2_comp ${ARGN})
    if(NOT TARGET Qt6::${_qtros2_comp})
      continue()
    endif()
    get_target_property(_qtros2_iface_libs Qt6::${_qtros2_comp} INTERFACE_LINK_LIBRARIES)
    if(NOT _qtros2_iface_libs)
      continue()
    endif()
    foreach(_qtros2_lib ${_qtros2_iface_libs})
      # Match <pkg>::<pkg>__rosidl_typesupport_cpp (the canonical exported typesupport target)
      if(_qtros2_lib MATCHES "^([A-Za-z0-9_]+)::([A-Za-z0-9_]+)__rosidl_typesupport_cpp$")
        set(_qtros2_src_pkg "${CMAKE_MATCH_1}")
        set_property(GLOBAL PROPERTY QTROS2_SOURCE_PKG_${_qtros2_src_pkg} "Qt6::${_qtros2_comp}")
        break()
      endif()
    endforeach()
    unset(_qtros2_iface_libs)
    unset(_qtros2_lib)
    unset(_qtros2_src_pkg)
  endforeach()
  unset(_qtros2_comp)
endfunction()

function(qt_ros2_configure_target _qt_ros2_app_target)
  cmake_parse_arguments(ARG "" "" "CAPABILITIES;MODULES;IMPORT_PACKAGES" ${ARGN})

  if(NOT ARG_CAPABILITIES)
    message(FATAL_ERROR "qt_ros2_configure_target: CAPABILITIES argument required (e.g. PUBLISHER SUBSCRIBER SERVICE ACTION)")
  endif()

  # Validate CAPABILITIES values
  set(_valid_types MESSAGES PUBLISHER SUBSCRIBER SERVICE ACTION)
  foreach(_t ${ARG_CAPABILITIES})
    string(TOUPPER "${_t}" _t_upper)
    if(NOT _t_upper IN_LIST _valid_types)
      message(WARNING "qt_ros2_configure_target: unknown CAPABILITIES value '${_t}'; expected one of ${_valid_types}")
    endif()
  endforeach()

  # Find ROS2 / ament packages so that INTERFACE_LINK_LIBRARIES of Qt6::QtRos2*
  # modules resolve correctly. The auto-generated Qt cmake configs don't call
  # find_dependency() for ament message packages; we must find them first.
  if(NOT TARGET rclcpp::rclcpp)
    # Locate FindWrapRos2.cmake alongside this file or via CMAKE_MODULE_PATH
    get_filename_component(_qtros2_cmake_dir "${CMAKE_CURRENT_LIST_FILE}" DIRECTORY)
    set(_wrapros2_candidates
        "${_qtros2_cmake_dir}/FindWrapRos2.cmake"  # installed or source cmake/ dir
    )
    set(_wrapros2_found FALSE)
    foreach(_candidate ${_wrapros2_candidates})
      get_filename_component(_candidate "${_candidate}" ABSOLUTE)
      if(EXISTS "${_candidate}")
        include("${_candidate}")
        set(_wrapros2_found TRUE)
        break()
      endif()
    endforeach()
    if(NOT _wrapros2_found)
      find_package(WrapRos2 QUIET)  # fallback via CMAKE_MODULE_PATH
    endif()
    unset(_wrapros2_candidates)
    unset(_wrapros2_found)
    unset(_qtros2_cmake_dir)
  endif()

  # Ensure rosidl_generator_qtros2 helpers (qtros2_generate_from_package etc.) are available.
  if(NOT COMMAND qtros2_generate_from_package)
    # The rosidl_generator_qtros2 cmake files are installed alongside this file.
    # Set the DIR hint so find_package() can locate them without CMAKE_PREFIX_PATH.
    if(NOT rosidl_generator_qtros2_FOUND AND NOT DEFINED rosidl_generator_qtros2_DIR)
      set(_qtros2_macros_cmake_dir "${CMAKE_CURRENT_FUNCTION_LIST_DIR}")
      set(_qtros2_gen_check "${_qtros2_macros_cmake_dir}/rosidl_generator_qtros2Config.cmake")
      if(EXISTS "${_qtros2_gen_check}")
        set(rosidl_generator_qtros2_DIR "${_qtros2_macros_cmake_dir}"
            CACHE PATH "Path to rosidl_generator_qtros2 cmake directory" FORCE)
      endif()
      unset(_qtros2_macros_cmake_dir)
      unset(_qtros2_gen_check)
    endif()
    find_package(rosidl_generator_qtros2 REQUIRED)
  endif()

  # Find all ROS2 message packages whose typesupport targets are referenced in
  # INTERFACE_LINK_LIBRARIES of the installed Qt6 QtRos2 modules.
  foreach(_ros2_pkg IN ITEMS
    builtin_interfaces service_msgs unique_identifier_msgs
    std_msgs std_srvs geometry_msgs action_msgs
    rcl_interfaces composition_interfaces type_description_interfaces
    diagnostic_msgs lifecycle_msgs rosgraph_msgs shape_msgs
    sensor_msgs statistics_msgs nav_msgs trajectory_msgs
    stereo_msgs visualization_msgs)
    if(NOT ${_ros2_pkg}_FOUND)
      find_package(${_ros2_pkg} QUIET)
    endif()
  endforeach()
  unset(_ros2_pkg)

  # Ensure Ros2Core is available (it is a Qt6 component)
  if(NOT TARGET Qt6::Ros2Core)
    find_package(Qt6 REQUIRED COMPONENTS Ros2Core)
  endif()

  # Pre-find all known Qt6 QtRos2 modules in topological dependency order.
  # cmake 3.17+ (3.28 strictly) validates INTERFACE_LINK_LIBRARIES targets at
  # configure time inside set_target_properties, so we must find dependencies
  # BEFORE the modules that depend on them.  The auto-generated *Dependencies.cmake
  # files do not include find_dependency() for inter-QtRos2 module deps, so we
  # do it manually here in topological order.
  set(_qtros2_ordered_components
    # Level 1 – depend only on Ros2Core
    QtRos2BuiltinInterfaces
    QtRos2UniqueIdentifierMessages
    QtRos2StandardServices
    # Level 2 – depend on Level 1
    QtRos2RclInterfaces            # → BuiltinInterfaces
    QtRos2RosGraphMessages         # → BuiltinInterfaces
    QtRos2ServiceMessages          # → BuiltinInterfaces
    QtRos2StandardMessages         # → BuiltinInterfaces
    QtRos2StatisticsMessages       # → BuiltinInterfaces
    # Level 3 – depend on Level 2
    QtRos2ActionMessages           # → ServiceMessages, BuiltinInterfaces, UniqueIdentifier
    QtRos2CompositionInterfaces    # → RclInterfaces, ServiceMessages
    QtRos2DiagnosticsMessages      # → StandardMessages, ServiceMessages
    QtRos2GeometryMessages         # → StandardMessages
    QtRos2LifecycleMessages        # → ServiceMessages
    QtRos2TypeDescriptionInterfaces  # → ServiceMessages
    # Level 4 – depend on Level 3
    QtRos2NavigationMessages       # → GeometryMessages, StandardMessages, ServiceMessages
    QtRos2SensorMessages           # → GeometryMessages, StandardMessages, ServiceMessages
    QtRos2ShapeMessages            # → GeometryMessages
    QtRos2TrajectoryMessages       # → GeometryMessages, StandardMessages
    QtRos2VisualizationMessages    # → GeometryMessages, SensorMessages, StandardMessages
    # Level 5 – depend on Level 4
    QtRos2StereoMessages           # → SensorMessages, StandardMessages
  )
  foreach(_qtros2_comp ${_qtros2_ordered_components})
    if(NOT TARGET Qt6::${_qtros2_comp})
      find_package(Qt6 COMPONENTS ${_qtros2_comp} QUIET)
    endif()
  endforeach()

  # Register ALL found pre-built Qt ROS2 modules (not just ARG_MODULES) in the global
  # source-package → target registry so that qtros2_generate_from_package() can resolve
  # them as IDL-level transitive dependencies (e.g. builtin_interfaces for tf2_msgs).
  set(_qtros2_found_comps "")
  foreach(_qtros2_comp ${_qtros2_ordered_components})
    if(TARGET Qt6::${_qtros2_comp})
      list(APPEND _qtros2_found_comps "${_qtros2_comp}")
    endif()
  endforeach()
  _qtros2_register_prebuilt_modules(${_qtros2_found_comps})
  unset(_qtros2_found_comps)
  unset(_qtros2_ordered_components)
  unset(_qtros2_comp)

  # Collect link targets for the explicitly requested Qt modules
  foreach(_pkg ${ARG_MODULES})
    if(TARGET Qt6::${_pkg})
      list(APPEND _pkg_link_targets Qt6::${_pkg})
    elseif(TARGET ${_pkg})
      list(APPEND _pkg_link_targets ${_pkg})
    else()
      message(WARNING "qt_ros2_configure_target: module '${_pkg}' not found as a target; skipping link")
    endif()
  endforeach()

  # Generate Qt/QML type wrappers for each external ROS2 package and link them.
  # The generated QML module URI is "QtRos2.Imported.<CamelCase>" and the cmake target is
  # "<package>_qtros2" (e.g. turtlesim -> QtRos2.Imported.Turtlesim / turtlesim_qtros2).
  foreach(_ros2_pkg ${ARG_IMPORT_PACKAGES})
    # Convert package name to CamelCase for the URI: turtlesim -> Turtlesim
    string(REPLACE "_" ";" _ros2_pkg_parts "${_ros2_pkg}")
    set(_ros2_pkg_camel "")
    foreach(_part ${_ros2_pkg_parts})
      string(SUBSTRING "${_part}" 0 1 _first)
      string(TOUPPER "${_first}" _first_upper)
      string(SUBSTRING "${_part}" 1 -1 _rest)
      string(APPEND _ros2_pkg_camel "${_first_upper}${_rest}")
    endforeach()
    set(_ros2_gen_target "${_ros2_pkg}_qtros2")
    set(_ros2_uri "QtRos2.Imported.${_ros2_pkg_camel}")
    set(_ros2_outdir "${CMAKE_CURRENT_BINARY_DIR}/QtRos2/Imported/${_ros2_pkg_camel}")
    qtros2_generate_from_package(
      TARGET "${_ros2_gen_target}"
      SOURCE_PACKAGE "${_ros2_pkg}"
      QML_MODULE_URI "${_ros2_uri}"
      QML_OUTPUT_DIRECTORY "${_ros2_outdir}"
    )
    # qtros2_generate_from_package converts TARGET to CamelCase internally;
    # use the same conversion to get the actual cmake target name for linking.
    _qtros2_to_camel_case("${_ros2_gen_target}" _ros2_cmake_target)
    list(APPEND _pkg_link_targets "${_ros2_cmake_target}")
    unset(_ros2_pkg_parts)
    unset(_ros2_pkg_camel)
    unset(_ros2_gen_target)
    unset(_ros2_uri)
    unset(_ros2_outdir)
  endforeach()

  # Link the target
  if(TARGET ${_qt_ros2_app_target})
    target_link_libraries(${_qt_ros2_app_target} PRIVATE Qt6::Ros2Core ${_pkg_link_targets})
  else()
    message(WARNING "qt_ros2_configure_target: target '${_qt_ros2_app_target}' does not exist yet; "
      "call qt_ros2_configure_target after qt_add_executable/qt_add_qml_module.")
  endif()
endfunction()
