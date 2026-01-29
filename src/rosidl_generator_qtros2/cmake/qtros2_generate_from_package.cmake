# Copyright (C) 2022 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

# Generate Qt/QML bindings for a ROS interface package

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
  find_package(qtros2_core REQUIRED)
  find_package(Qt6 REQUIRED COMPONENTS Core Qml)

  # Compatibility for distros without rosidl_find_package_idl (e.g., Galactic)
  if(NOT COMMAND rosidl_find_package_idl)
    include("${rosidl_generator_qtros2_DIR}/rosidl_find_package_idl_compat.cmake")
  endif()

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
  set(_qtros2_generator_target "${ARG_TARGET}")

  set(_qtros2_pkg_dependencies ${_dependencies})

  set(_qtros2_interface_deps_var "_qtros2_interface_deps_${_qtros2_generator_target}_qtcpp")
  set(${_qtros2_interface_deps_var} "${_interface_package_deps}")
  set(_qtros2_source_package_var "_qtros2_source_package_${_qtros2_generator_target}_qtcpp")
  set(${_qtros2_source_package_var} "${ARG_SOURCE_PACKAGE}")

  # Always set QML module URI (required parameter)
  set(${_qtros2_generator_target}_qtros2_qml_module_uri_qtcpp "${ARG_QML_MODULE_URI}")
  set_property(GLOBAL APPEND PROPERTY QTROS2_URI_REGISTRY
    "${ARG_SOURCE_PACKAGE}=${ARG_QML_MODULE_URI}")

  if(ARG_QML_OUTPUT_DIRECTORY)
    set(${_qtros2_generator_target}_qtros2_qml_output_dir_qtcpp "${ARG_QML_OUTPUT_DIRECTORY}")
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
      if(TARGET ${_dep_target}_qtcpp)
        add_dependencies(${_qtros2_generator_target}_qtcpp ${_dep_target}_qtcpp)
      elseif(TARGET ${_dep_target})
        add_dependencies(${_qtros2_generator_target}_qtcpp ${_dep_target})
      else()
        message(WARNING "QtROS2: DEPENDS target '${_dep_target}' not found. CMake will determine build order automatically.")
      endif()
    endforeach()
  endif()

  unset(${_qtros2_generator_target}_qtros2_qml_module_uri_qtcpp)

  if(ARG_QML_OUTPUT_DIRECTORY)
    unset(${_qtros2_generator_target}_qtros2_qml_output_dir_qtcpp)
  endif()

  unset(rosidl_generate_interfaces_TARGET)
  unset(rosidl_generate_interfaces_IDL_TUPLES)
  unset(rosidl_generate_interfaces_ABS_IDL_FILES)
  unset(rosidl_generate_interfaces_DEPENDENCY_PACKAGE_NAMES)

  set(_qt_wrapper_packages "")
  get_property(_qtros2_local_wrappers GLOBAL PROPERTY QTROS2_LOCAL_WRAPPER_PACKAGES)
  if(NOT _qtros2_local_wrappers)
    set(_qtros2_local_wrappers "")
  endif()
  list(APPEND _qtros2_local_wrappers "${_qtros2_generator_target}")
  set_property(GLOBAL PROPERTY QTROS2_LOCAL_WRAPPER_PACKAGES "${_qtros2_local_wrappers}")

  if(TARGET ${_qtros2_generator_target}_qtcpp)
    # Link against the source ROS package typesupport target
    # This target includes all dependencies transitively via INTERFACE_LINK_LIBRARIES
    target_link_libraries(${_qtros2_generator_target}_qtcpp
      PUBLIC ${ARG_SOURCE_PACKAGE}::${ARG_SOURCE_PACKAGE}__rosidl_typesupport_cpp
    )

    foreach(_qt_dep ${_interface_package_deps})
      set(_qt_wrapper_pkg "qtros2_${_qt_dep}")

      get_property(_qtros2_local_wrappers GLOBAL PROPERTY QTROS2_LOCAL_WRAPPER_PACKAGES)
      list(FIND _qtros2_local_wrappers "${_qt_wrapper_pkg}" _qt_wrapper_local_index)
      set(_qtros2_wrapper_local FALSE)
      if(_qt_wrapper_local_index GREATER -1)
        set(_qtros2_wrapper_local TRUE)
      endif()

      if(NOT _qtros2_wrapper_local)
        find_package(${_qt_wrapper_pkg} QUIET)
        if(NOT ${_qt_wrapper_pkg}_FOUND)
          message(FATAL_ERROR
            "\n"
            "========================================\n"
            "QtROS2 Dependency Error\n"
            "========================================\n"
            "Package '${ARG_SOURCE_PACKAGE}' depends on '${_qt_dep}' (found in IDL files),\n"
            "but Qt wrapper '${_qt_wrapper_pkg}' is not available.\n"
            "\n"
            "Solution:\n"
            "  1. Generate Qt wrappers for '${_qt_dep}' BEFORE '${ARG_SOURCE_PACKAGE}':\n"
            "     \n"
            "     qtros2_generate_from_package(\n"
            "         TARGET ${_qt_wrapper_pkg}\n"
            "         SOURCE_PACKAGE ${_qt_dep}\n"
            "     )\n"
            "     \n"
            "  2. OR specify dependency order explicitly:\n"
            "     \n"
            "     qtros2_generate_from_package(\n"
            "         TARGET ${_qtros2_generator_target}\n"
            "         SOURCE_PACKAGE ${ARG_SOURCE_PACKAGE}\n"
            "         DEPENDS ${_qt_wrapper_pkg}  # Ensures correct order\n"
            "     )\n"
            "     \n"
            "  3. OR install ${_qt_wrapper_pkg} to your workspace\n"
            "\n"
            "========================================\n")
        endif()
      endif()

      set(_qtros2_wrapper_target "${_qt_wrapper_pkg}::${_qt_wrapper_pkg}_qtcpp")
      set(_qtros2_wrapper_alt_target "${_qt_wrapper_pkg}_qtcpp")

      if(_qtros2_wrapper_local)
        if(TARGET ${_qtros2_wrapper_alt_target})
          target_link_libraries(${_qtros2_generator_target}_qtcpp PUBLIC ${_qtros2_wrapper_alt_target})
          list(APPEND _qt_wrapper_packages ${_qt_wrapper_pkg})
        else()
          message(FATAL_ERROR
            "QtROS2: Locally generated wrapper ${_qt_wrapper_pkg}_qtcpp not found for interface dependency ${_qt_dep}.
            This package is referenced in the IDL files of ${ARG_SOURCE_PACKAGE}.")
        endif()
      elseif(${_qt_wrapper_pkg}_FOUND)
        # Link against the installed Qt wrapper package
        if(TARGET "${_qtros2_wrapper_target}")
          target_link_libraries(${_qtros2_generator_target}_qtcpp PUBLIC ${_qtros2_wrapper_target})
          list(APPEND _qt_wrapper_packages ${_qt_wrapper_pkg})
        elseif(TARGET ${_qtros2_wrapper_alt_target})
          target_link_libraries(${_qtros2_generator_target}_qtcpp PUBLIC ${_qtros2_wrapper_alt_target})
          list(APPEND _qt_wrapper_packages ${_qt_wrapper_pkg})
        else()
          message(FATAL_ERROR
            "QtROS2: Expected target ${_qt_wrapper_pkg}_qtcpp for interface dependency ${_qt_dep} but it was not found.
            This package is referenced in the IDL files of ${ARG_SOURCE_PACKAGE}.")
        endif()
      else()
        message(FATAL_ERROR
          "QtROS2: Missing required Qt wrapper package ${_qt_wrapper_pkg} for interface dependency ${_qt_dep}.
          This package is referenced in the IDL files of ${ARG_SOURCE_PACKAGE}.
          Make sure to generate Qt wrappers for ${_qt_dep} before ${ARG_SOURCE_PACKAGE}.")
      endif()
    endforeach()

    # Export Qt wrapper dependencies for the wrapper package to use
    # Only export: qtros2_core, Qt6, source package, and Qt wrapper packages
    # Do NOT export ROS infrastructure packages (rosidl_*, fastcdr, etc.)
    set(_qtros2_export_deps
      qtros2_core
      Qt6
      ${ARG_SOURCE_PACKAGE}
      ${_qt_wrapper_packages}
    )
    list(REMOVE_DUPLICATES _qtros2_export_deps)
    set(${_qtros2_generator_target}_QTROS2_DEPENDENCIES "${_qtros2_export_deps}")

  else()
    message(WARNING "QtROS2: ${_qtros2_generator_target}_qtcpp target not found after generation")
  endif()

endmacro()
