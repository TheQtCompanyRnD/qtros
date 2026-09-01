# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

# CMake helper function to analyze IDL dependencies
#
# This function parses IDL files to extract actual interface package dependencies,
# rather than relying on CMake's full dependency list.

function(qtros2_analyze_idl_dependencies)
  cmake_parse_arguments(
    ARG "" "PACKAGE_NAME;OUTPUT_VARIABLE" "IDL_TUPLES" ${ARGN}
  )

  if(NOT ARG_PACKAGE_NAME)
    message(FATAL_ERROR "qtros2_analyze_idl_dependencies: PACKAGE_NAME required")
  endif()

  if(NOT ARG_OUTPUT_VARIABLE)
    message(FATAL_ERROR "qtros2_analyze_idl_dependencies: OUTPUT_VARIABLE required")
  endif()

  if(NOT ARG_IDL_TUPLES)
    # No IDL files to analyze, return empty list
    set(${ARG_OUTPUT_VARIABLE} "" PARENT_SCOPE)
    return()
  endif()

  # Find Python interpreter
  find_package(Python3 REQUIRED COMPONENTS Interpreter)

  # Find the dependency analyzer script.
  # rosidl_generator_qtros2_BIN is always set to an absolute path by the Config file,
  # pointing to the generator __init__.py; dependency_analyzer.py lives in the same directory.
  get_filename_component(_analyzer_script "${rosidl_generator_qtros2_BIN}" DIRECTORY)
  set(_analyzer_script "${_analyzer_script}/dependency_analyzer.py")

  if(NOT EXISTS "${_analyzer_script}")
    message(WARNING "qtros2_analyze_idl_dependencies: Could not find dependency_analyzer.py, returning empty dependency list")
    set(${ARG_OUTPUT_VARIABLE} "" PARENT_SCOPE)
    return()
  endif()

  # Build list of absolute IDL file paths from tuples
  set(_idl_files "")
  foreach(_idl_tuple ${ARG_IDL_TUPLES})
    # IDL tuple format: "base_path:relative_path"
    string(REPLACE ":" ";" _tuple_parts "${_idl_tuple}")
    list(LENGTH _tuple_parts _tuple_parts_len)
    if(_tuple_parts_len EQUAL 2)
      list(GET _tuple_parts 0 _base_path)
      list(GET _tuple_parts 1 _rel_path)
      set(_abs_idl_file "${_base_path}/${_rel_path}")
      if(EXISTS "${_abs_idl_file}")
        list(APPEND _idl_files "${_abs_idl_file}")
      else()
        message(WARNING "IDL file does not exist: ${_abs_idl_file}")
      endif()
    endif()
  endforeach()

  if(NOT _idl_files)
    message(WARNING "qtros2_analyze_idl_dependencies: No valid IDL files found")
    set(${ARG_OUTPUT_VARIABLE} "" PARENT_SCOPE)
    return()
  endif()

  # Create output file path
  set(_deps_output_file "${CMAKE_CURRENT_BINARY_DIR}/qtros2_idl_deps_${ARG_PACKAGE_NAME}.txt")

  # Run dependency analyzer with CMake output format
  execute_process(
    COMMAND ${Python3_EXECUTABLE}
      "${_analyzer_script}"
      "${ARG_PACKAGE_NAME}"
      ${_idl_files}
      --format cmake
      --output "${_deps_output_file}"
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    RESULT_VARIABLE _analyzer_result
    ERROR_VARIABLE _analyzer_error
    OUTPUT_QUIET
  )

  if(NOT _analyzer_result EQUAL 0)
    message(WARNING "qtros2_analyze_idl_dependencies: Failed to analyze dependencies: ${_analyzer_error}")
    set(${ARG_OUTPUT_VARIABLE} "" PARENT_SCOPE)
    return()
  endif()

  # Read the output file
  if(EXISTS "${_deps_output_file}")
    file(READ "${_deps_output_file}" _deps_content)
    string(STRIP "${_deps_content}" _deps_content)

    # Convert semicolon-separated list to CMake list
    if(_deps_content)
      string(REPLACE ";" ";" _deps_list "${_deps_content}")
      set(${ARG_OUTPUT_VARIABLE} ${_deps_list} PARENT_SCOPE)
    else()
      set(${ARG_OUTPUT_VARIABLE} "" PARENT_SCOPE)
    endif()
  else()
    message(WARNING "qtros2_analyze_idl_dependencies: Output file not created: ${_deps_output_file}")
    set(${ARG_OUTPUT_VARIABLE} "" PARENT_SCOPE)
  endif()
endfunction()
