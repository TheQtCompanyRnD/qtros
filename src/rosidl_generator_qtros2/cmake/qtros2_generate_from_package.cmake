# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

# Generate Qt/QML bindings for a ROS interface package

# Helper: convert snake_case or any underscore-separated name to CamelCase.
# E.g. qt_ros2_builtin_interfaces → QtRos2BuiltinInterfaces
# If the input is already CamelCase (starts with uppercase), it is returned unchanged.
function(_qtros2_to_camel_case input output_var)
    if(input MATCHES "^[A-Z]")
        # Already CamelCase
        set(${output_var} "${input}" PARENT_SCOPE)
        return()
    endif()
    string(REPLACE "_" ";" _parts "${input}")
    set(_result "")
    foreach(_part ${_parts})
        string(SUBSTRING "${_part}" 0 1 _first)
        string(TOUPPER "${_first}" _first)
        string(SUBSTRING "${_part}" 1 -1 _rest)
        string(APPEND _result "${_first}${_rest}")
    endforeach()
    set(${output_var} "${_result}" PARENT_SCOPE)
endfunction()

macro(qtros2_generate_from_package)
  cmake_parse_arguments(
    ARG "" "SOURCE_PACKAGE;QML_MODULE_URI;QML_OUTPUT_DIRECTORY;TARGET" "ADDITIONAL_INTERFACES;DEPENDS" ${ARGN}
  )

  if(NOT ARG_SOURCE_PACKAGE)
    message(FATAL_ERROR "qtros2_generate_from_package: SOURCE_PACKAGE argument required")
  endif()

  if(NOT ARG_TARGET)
    message(FATAL_ERROR "qtros2_generate_from_package: TARGET argument required")
  endif()

  if(NOT ARG_QML_MODULE_URI)
    message(FATAL_ERROR "qtros2_generate_from_package: QML_MODULE_URI argument required")
  endif()

  find_package(rosidl_cmake REQUIRED)
  # When building as a CMake sub-project, Ros2Core is brought in via
  # add_subdirectory(core) before this macro is called, so the target already
  # exists. As a Qt6 component, use find_package(Qt6 COMPONENTS Ros2Core).
  if(NOT TARGET Qt6::Ros2Core AND NOT TARGET Ros2Core)
    find_package(Qt6 REQUIRED COMPONENTS Ros2Core)
  endif()
  set(qtros2_core_FOUND TRUE)
  # Note: Qt6 Core/Qml targets are already available in the Qt internal build context.
  # find_package(Qt6 Core Qml) would re-trigger loading of Qt6QmlPlugins.cmake for each
  # new directory scope, causing duplicate plugin alias errors. Omit it here.

  if(NOT COMMAND qtros2_analyze_idl_dependencies)
    include("${rosidl_generator_qtros2_DIR}/analyze_idl_dependencies.cmake")
  endif()

  find_package(${ARG_SOURCE_PACKAGE} REQUIRED)

  if(NOT DEFINED ${ARG_SOURCE_PACKAGE}_IDL_FILES)
    message(FATAL_ERROR "Package ${ARG_SOURCE_PACKAGE} has no IDL files")
  endif()

  set(_interface_files "")
  set(_abs_idl_files "")

  foreach(_idl_file ${${ARG_SOURCE_PACKAGE}_IDL_FILES})
    rosidl_find_package_idl(_abs_idl_file "${ARG_SOURCE_PACKAGE}" "${_idl_file}")

    if(NOT _abs_idl_file)
      message(FATAL_ERROR "Failed to resolve IDL file ${_idl_file} from ${ARG_SOURCE_PACKAGE}")
    endif()

    set(_base_path "${_abs_idl_file}")
    string(REPLACE "/" ";" _idl_components "${_idl_file}")
    foreach(_component ${_idl_components})
      get_filename_component(_base_path "${_base_path}" DIRECTORY)
    endforeach()

    list(APPEND _interface_files "${_base_path}:${_idl_file}")
  endforeach()

  if(ARG_ADDITIONAL_INTERFACES)
    list(APPEND _interface_files ${ARG_ADDITIONAL_INTERFACES})
  endif()

  if(NOT _interface_files)
    message(FATAL_ERROR "No interface files found for package ${ARG_SOURCE_PACKAGE}")
  endif()

  set(_abs_idl_files "")
  foreach(_tuple ${_interface_files})
    string(FIND "${_tuple}" ":" _qtros2_tuple_sep REVERSE)
    if(_qtros2_tuple_sep LESS 0)
      message(FATAL_ERROR "Invalid interface tuple '${_tuple}'. Expected '<base_path>:<relative_path>'.")
    endif()
    string(SUBSTRING "${_tuple}" 0 ${_qtros2_tuple_sep} _tuple_base)
    math(EXPR _qtros2_rel_start "${_qtros2_tuple_sep} + 1")
    string(SUBSTRING "${_tuple}" ${_qtros2_rel_start} -1 _tuple_relative)
    if(NOT EXISTS "${_tuple_base}/${_tuple_relative}")
      message(FATAL_ERROR "Resolved tuple ${_tuple} does not point to an existing IDL file")
    endif()
    list(APPEND _abs_idl_files "${_tuple_base}/${_tuple_relative}")
  endforeach()

  qtros2_analyze_idl_dependencies(
    PACKAGE_NAME "${ARG_SOURCE_PACKAGE}"
    IDL_TUPLES ${_interface_files}
    OUTPUT_VARIABLE _interface_package_deps
  )

  set(_dependencies "")
  if(DEFINED ${ARG_SOURCE_PACKAGE}_DEPENDENCIES)
    set(_dependencies ${${ARG_SOURCE_PACKAGE}_DEPENDENCIES})
    list(REMOVE_DUPLICATES _dependencies)
    foreach(_dep ${_dependencies})
      find_package(${_dep} REQUIRED)
    endforeach()
  endif()

  # Use the explicit TARGET name (required parameter)
  # If TARGET is snake_case (ament naming convention), convert to CamelCase for the Qt cmake target.
  _qtros2_to_camel_case("${ARG_TARGET}" _qtros2_generator_target)

  set(_qtros2_pkg_dependencies ${_dependencies})

  set(_qtros2_interface_deps_var "_qtros2_interface_deps_${_qtros2_generator_target}")
  set(${_qtros2_interface_deps_var} "${_interface_package_deps}")
  set(_qtros2_source_package_var "_qtros2_source_package_${_qtros2_generator_target}")
  set(${_qtros2_source_package_var} "${ARG_SOURCE_PACKAGE}")

  # Always set QML module URI (required parameter)
  set(${_qtros2_generator_target}_qtros2_qml_module_uri "${ARG_QML_MODULE_URI}")
  set_property(GLOBAL APPEND PROPERTY QTROS2_URI_REGISTRY
    "${ARG_SOURCE_PACKAGE}=${ARG_QML_MODULE_URI}")
  # Register source-package → Qt target mapping for dependency lookup
  set_property(GLOBAL PROPERTY QTROS2_SOURCE_PKG_${ARG_SOURCE_PACKAGE} "${_qtros2_generator_target}")

  if(ARG_QML_OUTPUT_DIRECTORY)
    set(${_qtros2_generator_target}_qtros2_qml_output_dir "${ARG_QML_OUTPUT_DIRECTORY}")
  endif()

  set(rosidl_generate_interfaces_TARGET "${_qtros2_generator_target}")
  set(rosidl_generate_interfaces_IDL_TUPLES "${_interface_files}")
  set(rosidl_generate_interfaces_ABS_IDL_FILES "${_abs_idl_files}")
  set(rosidl_generate_interfaces_DEPENDENCY_PACKAGE_NAMES "${_dependencies}")

  include("${rosidl_generator_qtros2_DIR}/rosidl_generator_qtros2_generate_interfaces.cmake")

  unset(${_qtros2_interface_deps_var})
  unset(${_qtros2_source_package_var})

  if(ARG_DEPENDS)
    foreach(_dep_target ${ARG_DEPENDS})
      if(TARGET ${_dep_target})
        add_dependencies(${_qtros2_generator_target} ${_dep_target})
      else()
        message(WARNING "QtROS2: DEPENDS target '${_dep_target}' not found. CMake will determine build order automatically.")
      endif()
    endforeach()
  endif()

  unset(${_qtros2_generator_target}_qtros2_qml_module_uri)

  if(ARG_QML_OUTPUT_DIRECTORY)
    unset(${_qtros2_generator_target}_qtros2_qml_output_dir)
  endif()

  unset(rosidl_generate_interfaces_TARGET)
  unset(rosidl_generate_interfaces_IDL_TUPLES)
  unset(rosidl_generate_interfaces_ABS_IDL_FILES)
  unset(rosidl_generate_interfaces_DEPENDENCY_PACKAGE_NAMES)

  set(_qt_wrapper_packages "")
  # Register this target in the local wrapper registry
  set_property(GLOBAL APPEND PROPERTY QTROS2_LOCAL_WRAPPER_PACKAGES "${_qtros2_generator_target}")

  if(TARGET ${_qtros2_generator_target})
    # Link against the source ROS package typesupport target
    target_link_libraries(${_qtros2_generator_target}
      PUBLIC ${ARG_SOURCE_PACKAGE}::${ARG_SOURCE_PACKAGE}__rosidl_typesupport_cpp
    )

    foreach(_qt_dep ${_interface_package_deps})
      # Look up the Qt module name registered when that dependency was generated
      get_property(_dep_qt_target GLOBAL PROPERTY QTROS2_SOURCE_PKG_${_qt_dep})

      if(_dep_qt_target)
        # Locally generated wrapper with Qt-style name
        if(TARGET ${_dep_qt_target})
          target_link_libraries(${_qtros2_generator_target} PUBLIC ${_dep_qt_target})
          list(APPEND _qt_wrapper_packages ${_dep_qt_target})
        else()
          message(FATAL_ERROR
            "QtROS2: Locally registered wrapper '${_dep_qt_target}' for '${_qt_dep}' not found as a target.\n"
            "Ensure it is added via qtros2_generate_from_package() before '${ARG_SOURCE_PACKAGE}'.")
        endif()
      else()
        # Not locally generated — try an installed ament wrapper package (old-style naming)
        set(_qt_wrapper_pkg "qtros2_${_qt_dep}")
        find_package(${_qt_wrapper_pkg} QUIET)
        if(NOT ${_qt_wrapper_pkg}_FOUND)
          message(FATAL_ERROR
            "\n"
            "========================================\n"
            "QtROS2 Dependency Error\n"
            "========================================\n"
            "Package '${ARG_SOURCE_PACKAGE}' depends on '${_qt_dep}' (found in IDL files),\n"
            "but Qt wrapper for '${_qt_dep}' is not available.\n"
            "\n"
            "Solution:\n"
            "  1. Generate Qt wrappers for '${_qt_dep}' BEFORE '${ARG_SOURCE_PACKAGE}':\n"
            "     \n"
            "     qtros2_generate_from_package(\n"
            "         TARGET QtRos2<Name>\n"
            "         SOURCE_PACKAGE ${_qt_dep}\n"
            "     )\n"
            "     \n"
            "  2. OR install the Qt wrapper for '${_qt_dep}' to your workspace\n"
            "\n"
            "========================================\n")
        endif()
        set(_qtros2_wrapper_target "${_qt_wrapper_pkg}::${_qt_wrapper_pkg}_qtcpp")
        set(_qtros2_wrapper_alt_target "${_qt_wrapper_pkg}_qtcpp")
        if(TARGET "${_qtros2_wrapper_target}")
          target_link_libraries(${_qtros2_generator_target} PUBLIC ${_qtros2_wrapper_target})
          list(APPEND _qt_wrapper_packages ${_qt_wrapper_pkg})
        elseif(TARGET ${_qtros2_wrapper_alt_target})
          target_link_libraries(${_qtros2_generator_target} PUBLIC ${_qtros2_wrapper_alt_target})
          list(APPEND _qt_wrapper_packages ${_qt_wrapper_pkg})
        else()
          message(FATAL_ERROR
            "QtROS2: Expected target for wrapper '${_qt_wrapper_pkg}' (dep '${_qt_dep}') not found.")
        endif()
      endif()
    endforeach()

    # Export Qt wrapper dependencies for the wrapper package to use
    set(_qtros2_export_deps
      Ros2Core
      Qt6
      ${ARG_SOURCE_PACKAGE}
      ${_qt_wrapper_packages}
    )
    list(REMOVE_DUPLICATES _qtros2_export_deps)
    set(${_qtros2_generator_target}_QTROS2_DEPENDENCIES "${_qtros2_export_deps}")

  else()
    message(WARNING "QtROS2: target '${_qtros2_generator_target}' not found after generation")
  endif()

endmacro()

# qt_ros2_configure_target() is defined in QtRos2Macros.cmake (cmake/ directory of the source tree,
# installed alongside Qt6Ros2Core). Include it from the source tree if not already loaded.
if(NOT COMMAND qt_ros2_configure_target)
  get_filename_component(_qtros2_macros_dir "${CMAKE_CURRENT_LIST_FILE}" DIRECTORY)
  set(_qtros2_macros_candidates
    "${_qtros2_macros_dir}/../../../cmake/QtRos2Macros.cmake"  # source tree
    "${_qtros2_macros_dir}/QtRos2Macros.cmake"                 # installed alongside
  )
  foreach(_qtros2_macros_candidate ${_qtros2_macros_candidates})
    get_filename_component(_qtros2_macros_candidate "${_qtros2_macros_candidate}" ABSOLUTE)
    if(EXISTS "${_qtros2_macros_candidate}")
      include("${_qtros2_macros_candidate}")
      break()
    endif()
  endforeach()
  unset(_qtros2_macros_dir)
  unset(_qtros2_macros_candidates)
  unset(_qtros2_macros_candidate)
endif()

