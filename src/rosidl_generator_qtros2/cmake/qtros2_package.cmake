# Copyright (C) 2022 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

# Macro to finalize and install a QtROS2 wrapper package
#
# This macro handles all the installation boilerplate for QtROS2 wrapper packages:
# 1. Installs the Qt library target
# 2. Installs headers
# 3. Installs QML modules
# 4. Installs metatypes JSON
# 5. Registers QML import path environment hooks
# 6. Exports targets and dependencies
# 7. Calls ament_package()
#
# Usage:
#   qtros2_package(TARGET <target_name>)
#
# Arguments:
#   TARGET - The target name (usually ${PROJECT_NAME})
#
# This replaces all the manual installation code in wrapper packages.

macro(qtros2_package)
  cmake_parse_arguments(ARG "" "TARGET" "" ${ARGN})

  if(NOT ARG_TARGET)
    message(FATAL_ERROR "qtros2_package: TARGET argument required")
  endif()

  # Ensure ament_cmake is available for installation and export
  find_package(ament_cmake REQUIRED)

  set(_qtros2_pkg_target "${ARG_TARGET}_qtcpp")

  if(TARGET ${_qtros2_pkg_target})
    # Get QML module URI for installation paths
    get_target_property(_qml_uri ${_qtros2_pkg_target} QT_QML_MODULE_URI)
    if(_qml_uri)
      string(REPLACE "." "/" _qml_module_path "${_qml_uri}")
      string(REPLACE "/" ";" _qml_path_parts "${_qml_module_path}")
      list(GET _qml_path_parts 0 _qml_module_root)
    else()
      set(_qml_module_root "QtROS2")
    endif()

    # Install library
    install(
      TARGETS ${_qtros2_pkg_target}
      EXPORT ${_qtros2_pkg_target}__targets
      ARCHIVE DESTINATION lib
      LIBRARY DESTINATION lib
      RUNTIME DESTINATION bin
    )

    # Install headers
    install(
      DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}/${ARG_TARGET}/include/${ARG_TARGET}/"
      DESTINATION "include/${ARG_TARGET}"
    )

    # Install QML module directory (plugin + qmldir + qmltypes)
    install(
      DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/qml/${_qml_module_root}"
      DESTINATION "lib/qt6/qml"
    )

    # Install metatypes JSON for dependent modules
    get_target_property(_metatypes_file ${_qtros2_pkg_target} INTERFACE_QT_META_TYPES_BUILD_FILE)
    if(_metatypes_file AND EXISTS "${_metatypes_file}")
      install(
        FILES "${_metatypes_file}"
        DESTINATION "lib/metatypes"
      )
    endif()

    # Note: Target dependencies are already linked via target_link_libraries()
    # in qtros2_generate_from_package.cmake using standard CMake, which properly
    # handles transitive dependencies. The install(EXPORT) command will automatically
    # preserve these link relationships in the generated *Export.cmake files.
    # We only need ament_export_dependencies() below to tell downstream packages
    # which packages to find_package().

    # Environment hooks for QML import path
    set(_qtros2_env_hooks
      "${rosidl_generator_qtros2_DIR}/environment_hooks/qtros2_qml_import_path.sh"
      "${rosidl_generator_qtros2_DIR}/environment_hooks/qtros2_qml_import_path.dsv"
    )
    ament_environment_hooks(${_qtros2_env_hooks})

    # Export targets and dependencies
    ament_export_targets(${_qtros2_pkg_target}__targets HAS_LIBRARY_TARGET)

    # Export dependencies (computed by generator)
    if(DEFINED ${ARG_TARGET}_QTROS2_DEPENDENCIES)
      ament_export_dependencies(${${ARG_TARGET}_QTROS2_DEPENDENCIES})
    else()
      message(WARNING "QtROS2: ${ARG_TARGET}_QTROS2_DEPENDENCIES not set by generator. This may cause dependency issues.")
    endif()
  else()
    message(WARNING "QtROS2: Target ${_qtros2_pkg_target} not found. Skipping installation.")
  endif()

  # Call ament_package
  ament_package()
endmacro()