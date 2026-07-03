# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

# Generate Qt/QML wrapper code for ROS 2 interfaces
#
# This script is included automatically by rosidl_generate_interfaces()
# when rosidl_generator_qtros2 is in the workspace
#
# Available variables from rosidl_generate_interfaces():
#   - rosidl_generate_interfaces_TARGET
#   - rosidl_generate_interfaces_IDL_TUPLES
#   - rosidl_generate_interfaces_IDL_FILES
#   - rosidl_generate_interfaces_ABS_IDL_FILES
#   - rosidl_generate_interfaces_DEPENDENCY_PACKAGE_NAMES

function(_qtros2_compute_qml_uri pkg_name out_var)
  set(_normalized "${pkg_name}")
  string(REGEX REPLACE "^qtros2_" "" _normalized "${_normalized}")
  string(REPLACE "+" "_" _normalized "${_normalized}")
  string(REPLACE "-" "_" _normalized "${_normalized}")
  string(REPLACE "::" "_" _normalized "${_normalized}")
  string(REPLACE "_" ";" _parts "${_normalized}")
  set(_camel "")
  foreach(_part ${_parts})
    if(_part STREQUAL "")
      continue()
    endif()
    string(SUBSTRING "${_part}" 0 1 _first_char)
    string(TOUPPER "${_first_char}" _first_char)
    string(LENGTH "${_part}" _part_len)
    if(_part_len GREATER 1)
      string(SUBSTRING "${_part}" 1 -1 _rest_chars)
      string(TOLOWER "${_rest_chars}" _rest_chars)
    else()
      set(_rest_chars "")
    endif()
    string(APPEND _camel "${_first_char}${_rest_chars}")
  endforeach()
  if(NOT _camel)
    set(_camel "${pkg_name}")
  endif()
  set(${out_var} "QtRos2.${_camel}" PARENT_SCOPE)
endfunction()

# When building as a CMake sub-project, qtros2_core target already exists from
# add_subdirectory(core). As a Qt6 component, use find_package(Qt6 COMPONENTS Ros2Core).
if(NOT TARGET Qt6::Ros2Core AND NOT TARGET Ros2Core)
    find_package(Qt6 REQUIRED COMPONENTS Ros2Core)
endif()
set(qtros2_core_FOUND TRUE)
find_package(Qt6 COMPONENTS Core Qml REQUIRED)

set(_qtros2_generator_target "${rosidl_generate_interfaces_TARGET}")

# Determine QML module URI/path, allowing overrides from qtros2_generate_from_package
set(_custom_qml_module_uri "")
set(_qtros2_qml_uri_var "${_qtros2_generator_target}_qtros2_qml_module_uri")
if(DEFINED ${_qtros2_qml_uri_var})
  set(_custom_qml_module_uri "${${_qtros2_qml_uri_var}}")
endif()

if(_custom_qml_module_uri)
  set(_qml_module_uri "${_custom_qml_module_uri}")
else()
  set(_qml_module_root "QtRos2")
  set(_qml_module_suffix "${PROJECT_NAME}")
  string(REGEX REPLACE "^qtros2_" "" _qml_module_suffix "${_qml_module_suffix}")
  if(_qml_module_suffix STREQUAL "")
    set(_qml_module_suffix "${PROJECT_NAME}")
  endif()
  string(REPLACE "_" ";" _qml_module_parts "${_qml_module_suffix}")
  set(_qml_module_name "")
  foreach(_part ${_qml_module_parts})
    if(_part STREQUAL "")
      continue()
    endif()
    string(SUBSTRING "${_part}" 0 1 _first_char)
    string(TOUPPER "${_first_char}" _first_char)
    string(LENGTH "${_part}" _part_len)
    if(_part_len GREATER 1)
      string(SUBSTRING "${_part}" 1 -1 _rest_chars)
    else()
      set(_rest_chars "")
    endif()
    string(TOLOWER "${_rest_chars}" _rest_chars)
    string(APPEND _qml_module_name "${_first_char}${_rest_chars}")
  endforeach()
  if(NOT _qml_module_name)
    set(_qml_module_name "${PROJECT_NAME}")
  endif()
  set(_qml_module_uri "${_qml_module_root}.${_qml_module_name}")
endif()

set(_custom_qml_output_dir "")
set(_qtros2_qml_output_var "${_qtros2_generator_target}_qtros2_qml_output_dir")
if(DEFINED ${_qtros2_qml_output_var})
  set(_custom_qml_output_dir "${${_qtros2_qml_output_var}}")
endif()

string(REPLACE "." "/" _qml_module_path "${_qml_module_uri}")
if(_qml_module_path STREQUAL "")
  set(_qml_module_path "${PROJECT_NAME}")
endif()
string(REPLACE "/" ";" _qml_module_path_parts "${_qml_module_path}")
list(LENGTH _qml_module_path_parts _qml_module_path_parts_len)
if(_qml_module_path_parts_len GREATER 0)
  list(GET _qml_module_path_parts 0 _qml_module_root)
else()
  set(_qml_module_root "${_qml_module_path}")
endif()
if(_custom_qml_output_dir)
  set(_qml_output_directory "${_custom_qml_output_dir}")
else()
  set(_qml_output_directory "${CMAKE_CURRENT_BINARY_DIR}/qml/${_qml_module_path}")
endif()

# Target suffix for Qt wrappers
set(_target_suffix "")

# Output directory for generated files
set(_output_path "${CMAKE_CURRENT_BINARY_DIR}/${_qtros2_generator_target}/${_qtros2_generator_target}")
set(_generator_arguments_file "${CMAKE_CURRENT_BINARY_DIR}/rosidl_generator_qtros2__arguments__${_qtros2_generator_target}.json")

# Prepare dependencies
set(_dependencies "")
set(_dependency_package_names "")

# Extract dependency information
foreach(_pkg_name ${rosidl_generate_interfaces_DEPENDENCY_PACKAGE_NAMES})
  list(APPEND _dependency_package_names ${_pkg_name})

  foreach(_idl_file ${${_pkg_name}_IDL_FILES})
    # Use rosidl_cmake function to find IDL file
    rosidl_find_package_idl(_abs_idl_file "${_pkg_name}" "${_idl_file}")
    list(APPEND _dependencies "${_pkg_name}:${_abs_idl_file}")
  endforeach()
endforeach()

# Prefer IDL-analyzed dependencies if provided by qtros2_generate_from_package
set(_qtros2_interface_dep_var "_qtros2_interface_deps_${_qtros2_generator_target}")
set(_qtros2_source_pkg_var "_qtros2_source_package_${_qtros2_generator_target}")
# Resolve source package name early — used when building the generator command
set(_qtros2_source_package "")
if(DEFINED ${_qtros2_source_pkg_var})
  set(_qtros2_source_package "${${_qtros2_source_pkg_var}}")
endif()
set(_qtros2_interface_deps_list "")
if(DEFINED ${_qtros2_interface_dep_var})
  set(_qtros2_interface_deps_list ${${_qtros2_interface_dep_var}})
endif()
if(_qtros2_interface_deps_list)
  list(REMOVE_DUPLICATES _qtros2_interface_deps_list)
  if(DEFINED ${_qtros2_source_pkg_var})
    set(_qtros2_source_pkg_name "${${_qtros2_source_pkg_var}}")
    if(_qtros2_source_pkg_name)
      list(REMOVE_ITEM _qtros2_interface_deps_list "${_qtros2_source_pkg_name}")
    endif()
  endif()
  set(_dependency_package_names "${_qtros2_interface_deps_list}")
endif()

# Build QML imports list from package dependencies
# Exclude RCL infrastructure packages that are transitive deps but not used in IDL
set(_qtros2_qml_imports "QtRos2.Core/auto")
set(_qtros2_rcl_infrastructure "action_msgs;service_msgs;unique_identifier_msgs")

# Load URI registry for custom URI mappings (from qtros2_generate_from_package)
get_property(_qtros2_uri_registry GLOBAL PROPERTY QTROS2_URI_REGISTRY)
set(_qtros2_uri_map)
foreach(_entry ${_qtros2_uri_registry})
  string(REPLACE "=" ";" _parts "${_entry}")
  list(LENGTH _parts _parts_len)
  if(_parts_len EQUAL 2)
    list(GET _parts 0 _reg_pkg)
    list(GET _parts 1 _reg_uri)
    set(_qtros2_uri_map_${_reg_pkg} "${_reg_uri}")
  endif()
endforeach()

foreach(_qtros2_dep ${_dependency_package_names})
  # Skip RCL infrastructure packages unless directly referenced in IDL
  list(FIND _qtros2_rcl_infrastructure "${_qtros2_dep}" _is_rcl_infra)
  if(_is_rcl_infra GREATER -1)
    # TODO: Check if actually used in IDL files (would require analysis)
    # For now, skip these to avoid bloating QML imports
    continue()
  endif()

  if(_qtros2_dep STREQUAL "builtin_interfaces" OR _qtros2_dep MATCHES "_msgs$")
    # Check if there's a custom URI registered for this package
    if(DEFINED _qtros2_uri_map_${_qtros2_dep})
      set(_qtros2_dep_uri "${_qtros2_uri_map_${_qtros2_dep}}")
    else()
      # Use default URI computation
      _qtros2_compute_qml_uri("${_qtros2_dep}" _qtros2_dep_uri)
    endif()

    if(_qtros2_dep_uri)
      list(APPEND _qtros2_qml_imports "${_qtros2_dep_uri}/auto")
    endif()
  endif()
endforeach()
list(REMOVE_DUPLICATES _qtros2_qml_imports)

# Set up target dependencies (files that generator depends on)
file(GLOB_RECURSE _template_files
  "${rosidl_generator_qtros2_TEMPLATE_DIR}/*.em"
)
get_filename_component(_qtros2_py_dir "${rosidl_generator_qtros2_BIN}" DIRECTORY)
file(GLOB_RECURSE _qtros2_py_sources
  "${_qtros2_py_dir}/*.py"
)
set(_target_dependencies "${rosidl_generator_qtros2_BIN}")
list(APPEND _target_dependencies ${_template_files} ${_qtros2_py_sources})
list(REMOVE_DUPLICATES _target_dependencies)

# Write generator arguments
rosidl_write_generator_arguments(
  "${_generator_arguments_file}"
  PACKAGE_NAME "${_qtros2_generator_target}"
  IDL_TUPLES "${rosidl_generate_interfaces_IDL_TUPLES}"
  ROS_INTERFACE_DEPENDENCIES "${_dependencies}"
  OUTPUT_DIR "${_output_path}"
  TEMPLATE_DIR "${rosidl_generator_qtros2_TEMPLATE_DIR}"
  TARGET_DEPENDENCIES ${_target_dependencies}
)

# Find Python interpreter
find_package(Python3 REQUIRED COMPONENTS Interpreter)

# Run the generator

# Build qt_package_mapping JSON for the Python generator (maps ROS2 pkg → Qt module include dir)
set(_qt_pkg_map_json_pairs "")
foreach(_dep ${_dependency_package_names})
  get_property(_dep_qt_name GLOBAL PROPERTY QTROS2_SOURCE_PKG_${_dep})
  if(_dep_qt_name)
    # The property holds the CMake target name (e.g. "Qt6::QtRos2BuiltinInterfaces").
    # Strip the "Qt6::" namespace prefix to get the bare include-directory name.
    string(REGEX REPLACE "^Qt6::" "" _dep_include_prefix "${_dep_qt_name}")
    list(APPEND _qt_pkg_map_json_pairs "\"${_dep}\": \"${_dep_include_prefix}\"")
  endif()
endforeach()
list(JOIN _qt_pkg_map_json_pairs ", " _qt_pkg_map_json_body)
set(_qt_pkg_map_json "{${_qt_pkg_map_json_body}}")

set(_generator_cmd
  "${Python3_EXECUTABLE}"
  "-m" "rosidl_generator_qtros2"
  "--generator-arguments-file" "${_generator_arguments_file}"
  "--qt-package-mapping" "${_qt_pkg_map_json}"
)
if(_qtros2_source_package)
  list(APPEND _generator_cmd "--source-package" "${_qtros2_source_package}")
endif()

# Generate Qt/QML code at configure time (not build time)
# This is necessary for Qt Creator and other IDEs that need files to exist during CMake configure
set(_qtros2_generation_stamp "${CMAKE_CURRENT_BINARY_DIR}/.${_qtros2_generator_target}_qtros2_last_gen")
set(_qtros2_should_generate TRUE)
if(EXISTS "${_qtros2_generation_stamp}")
  set(_qtros2_should_generate FALSE)
  foreach(_idl_file ${rosidl_generate_interfaces_ABS_IDL_FILES})
    if(NOT EXISTS "${_idl_file}" OR "${_idl_file}" IS_NEWER_THAN "${_qtros2_generation_stamp}")
      set(_qtros2_should_generate TRUE)
      break()
    endif()
  endforeach()
  if(NOT _qtros2_should_generate)
    foreach(_dep ${_target_dependencies})
      if(NOT _dep)
        continue()
      endif()
      if(EXISTS "${_dep}" AND "${_dep}" IS_NEWER_THAN "${_qtros2_generation_stamp}")
        set(_qtros2_should_generate TRUE)
        break()
      endif()
    endforeach()
  endif()
endif()

if(_qtros2_should_generate)
  execute_process(
    COMMAND ${_generator_cmd}
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    RESULT_VARIABLE _gen_result
    OUTPUT_VARIABLE _gen_output
    ERROR_VARIABLE _gen_error
  )

  if(NOT _gen_result EQUAL 0)
    message(FATAL_ERROR "Failed to generate Qt/QML code for ${_qtros2_generator_target}:\n${_gen_error}")
  endif()

  execute_process(
    COMMAND ${CMAKE_COMMAND} -E touch "${_qtros2_generation_stamp}"
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
  )
else()
  message(STATUS "QtROS2: Skipping code generation for ${_qtros2_generator_target}; IDL files unchanged.")
endif()

# Load manifest of generated files produced by the generator
set(_generated_headers "")
set(_generated_sources "")
set(_generated_parent_folders "")

set(_qtros2_manifest "${_output_path}/qtros2_generated_files.cmake")
if(EXISTS "${_qtros2_manifest}")
  include("${_qtros2_manifest}")

  foreach(_header_rel ${_qtros2_generated_headers})
    list(APPEND _generated_headers "${_output_path}/${_header_rel}")
  endforeach()

  foreach(_source_rel ${_qtros2_generated_sources})
    list(APPEND _generated_sources "${_output_path}/${_source_rel}")
  endforeach()

  foreach(_iface ${_qtros2_generated_parent_folders})
    if(_iface AND NOT _iface IN_LIST _generated_parent_folders)
      list(APPEND _generated_parent_folders "${_iface}")
    endif()
  endforeach()
else()
  message(WARNING "QtROS2: Generated file manifest not found: ${_qtros2_manifest}")
endif()

# Create a custom target that depends on the IDL files for regeneration
add_custom_target(${rosidl_generate_interfaces_TARGET}${_target_suffix}_generated
  DEPENDS ${rosidl_generate_interfaces_ABS_IDL_FILES}
)

set(_generated_vars_cmake "${_output_path}/qtros2_module_vars.cmake")

# Make generated files relative to the output path (for use inside the included cmake file,
# where CMAKE_CURRENT_LIST_DIR == _output_path).
set(_relative_headers "")
set(_relative_sources "")
foreach(_header ${_generated_headers})
  file(RELATIVE_PATH _rel_header "${_output_path}" "${_header}")
  list(APPEND _relative_headers "${_rel_header}")
endforeach()
foreach(_source ${_generated_sources})
  file(RELATIVE_PATH _rel_source "${_output_path}" "${_source}")
  list(APPEND _relative_sources "${_rel_source}")
endforeach()

# Helper function to convert CMake list to Python list string
function(_cmake_list_to_python_list input_list output_var)
  if(NOT input_list)
    set(${output_var} "[]" PARENT_SCOPE)
  else()
    string(REPLACE ";" "', '" _temp "${input_list}")
    set(${output_var} "['${_temp}']" PARENT_SCOPE)
  endif()
endfunction()

# Convert CMake lists to Python lists for cmake vars generation
_cmake_list_to_python_list("${_qtros2_qml_imports}" _qml_imports_py)
_cmake_list_to_python_list("${_relative_headers}" _headers_py)
_cmake_list_to_python_list("${_relative_sources}" _sources_py)
_cmake_list_to_python_list("${_dependency_package_names}" _deps_py)
_cmake_list_to_python_list("${_generated_parent_folders}" _folders_py)

# Build dependency Qt target mapping
set(_dep_qt_targets_py "{")
foreach(_dep ${_dependency_package_names})
  get_property(_dep_qt_name GLOBAL PROPERTY QTROS2_SOURCE_PKG_${_dep})
  if(NOT _dep_qt_name)
    set(_dep_qt_name "")
  endif()
  string(APPEND _dep_qt_targets_py "'${_dep}': '${_dep_qt_name}', ")
endforeach()
string(APPEND _dep_qt_targets_py "}")

# Ensure output directory exists before generating cmake vars file
file(MAKE_DIRECTORY "${_output_path}")

# Generate qtros2_module_vars.cmake at configure time by calling generate_cmake_vars()
# directly from the Python generator — no static .em template file needed.
find_package(Python3 REQUIRED COMPONENTS Interpreter)
execute_process(
  COMMAND ${Python3_EXECUTABLE} -c "
import sys
from rosidl_generator_qtros2 import generate_cmake_vars
generate_cmake_vars(
    output_path='${_output_path}',
    target_name='${rosidl_generate_interfaces_TARGET}${_target_suffix}',
    qml_uri='${_qml_module_uri}',
    qml_imports=${_qml_imports_py},
    generated_headers=${_headers_py},
    generated_sources=${_sources_py},
    dependency_packages=${_deps_py},
    dependency_qt_targets=${_dep_qt_targets_py},
    generated_parent_folders=${_folders_py},
)
"
  WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
  RESULT_VARIABLE _cmake_gen_result
  OUTPUT_VARIABLE _cmake_gen_output
  ERROR_VARIABLE _cmake_gen_error
)

if(NOT _cmake_gen_result EQUAL 0)
  message(FATAL_ERROR "Failed to generate qtros2_module_vars.cmake for ${_qtros2_generator_target}:\n${_cmake_gen_error}")
endif()

# Include the generated variables.
# The included file sets: _qtros2_module_name, _qtros2_module_uri, _qtros2_module_imports,
# _qtros2_module_sources, _qtros2_module_public_include_dirs, _qtros2_module_public_libs,
# _qtros2_module_private_libs.
include("${_generated_vars_cmake}")

# Resolve relative source paths to absolute paths (relative to the output directory)
set(_qtros2_abs_sources "")
foreach(_src ${_qtros2_module_sources})
  if(IS_ABSOLUTE "${_src}")
    list(APPEND _qtros2_abs_sources "${_src}")
  else()
    list(APPEND _qtros2_abs_sources "${_output_path}/${_src}")
  endif()
endforeach()

if(QT_BUILDING_QT)
    # Inside the Qt build tree: use the full internal API (syncs headers, no private module, etc.)
    # Use ${PROJECT_VERSION_MAJOR}.0 so "auto" in IMPORTS resolves to the same Qt major version
    # as Core (which is also versioned at the Qt project version).
    qt_internal_add_qml_module(${_qtros2_module_name}
        URI "${_qtros2_module_uri}"
        VERSION "${PROJECT_VERSION_MAJOR}.0"
        NO_SYNC_QT
        NO_PRIVATE_MODULE
        EXCEPTIONS
        IMPORTS ${_qtros2_module_imports}
        SOURCES ${_qtros2_abs_sources}
        PUBLIC_INCLUDE_DIRECTORIES ${_qtros2_module_public_include_dirs}
        PUBLIC_LIBRARIES ${_qtros2_module_public_libs}
        LIBRARIES ${_qtros2_module_private_libs}
    )
else()
    # External project build (e.g. user app with ROS2_PACKAGES): use public Qt API.
    # Generated headers include QtRos2Core private headers, so the private module IS needed.
    # Suppress the cmake warning with Qt's own escape hatch since this is intentional.
    set(QT_NO_PRIVATE_MODULE_WARNING ON)
    find_package(Qt6 REQUIRED COMPONENTS Ros2CorePrivate)
    string(REPLACE "." "/" _qtros2_uri_path "${_qtros2_module_uri}")
    # For Qt-internal module dependencies, "/auto" resolves to the importing module's
    # version (1.0), but Qt-internal modules are registered at Qt's version (6.x).
    # Replace "/auto" with "/${QT_VERSION_MAJOR}" to get the right major version.
    # Sibling generated modules (QtRos2.Imported.*) are versioned at 1.0 like this
    # module, so leave their "/auto" alone — rewriting it to 6.0 would make the import
    # request a version that is not installed.
    set(_qtros2_external_imports "")
    foreach(_imp ${_qtros2_module_imports})
        if(NOT _imp MATCHES "^QtRos2\\.Imported\\.")
            string(REPLACE "/auto" "/${Qt6_VERSION_MAJOR}.0" _imp "${_imp}")
        endif()
        list(APPEND _qtros2_external_imports "${_imp}")
    endforeach()
    unset(_imp)
    qt_add_library(${_qtros2_module_name} STATIC)
    qt_add_qml_module(${_qtros2_module_name}
        URI "${_qtros2_module_uri}"
        VERSION 1.0
        OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${_qtros2_uri_path}"
        RESOURCE_PREFIX "/qt/qml"
        IMPORTS ${_qtros2_external_imports}
    )
    unset(_qtros2_external_imports)
    target_sources(${_qtros2_module_name} PRIVATE ${_qtros2_abs_sources})
    target_include_directories(${_qtros2_module_name}
        PUBLIC ${_qtros2_module_public_include_dirs})
    target_link_libraries(${_qtros2_module_name}
        PUBLIC ${_qtros2_module_public_libs})
    foreach(_lib ${_qtros2_module_private_libs})
        if(TARGET ${_lib})
            target_link_libraries(${_qtros2_module_name} PRIVATE ${_lib})
        endif()
    endforeach()
    unset(_lib)
    unset(_qtros2_uri_path)
endif()

# Add dependencies on code generation
add_dependencies(${_qtros2_module_name}
  ${rosidl_generate_interfaces_TARGET}${_target_suffix}_generated
)

set_property(TARGET ${_qtros2_module_name}
  APPEND PROPERTY AUTOGEN_TARGET_DEPENDS
    ${rosidl_generate_interfaces_TARGET}${_target_suffix}_generated
)

# Ensure QML tooling sees generated module path
set(_qtros2_qml_import_path "${QML_IMPORT_PATH}")
list(APPEND _qtros2_qml_import_path "${_qml_output_directory}")
list(REMOVE_DUPLICATES _qtros2_qml_import_path)
set(QML_IMPORT_PATH "${_qtros2_qml_import_path}" CACHE STRING "Qt QML import paths" FORCE)

if(TARGET ${rosidl_generate_interfaces_TARGET}${_target_suffix}_autogen)
  add_dependencies(${rosidl_generate_interfaces_TARGET}${_target_suffix}_autogen
    ${rosidl_generate_interfaces_TARGET}${_target_suffix}_generated
  )
endif()

# Add dependency from rosidl interface target to the Qt module target (only when they differ)
if(_target_suffix AND TARGET ${rosidl_generate_interfaces_TARGET})
  add_dependencies(${rosidl_generate_interfaces_TARGET} ${rosidl_generate_interfaces_TARGET}${_target_suffix})
endif()
