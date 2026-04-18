# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause



#### Inputs



#### Libraries

qt_find_package(Python MODULE)
if(Python_Interpreter_FOUND)
    # Make the Python executable globally available to the project (e.g. tools).
    set(QT_INTERNAL_ROS2_BRIDGE_PYTHON "${Python_EXECUTABLE}" CACHE STRING "" FORCE)
endif()



#### Tests

# Check that the Python packages required by urdf2quickexporter.py are importable.
# This is an execute_process test rather than a compile test because we are checking
# Python import availability, not C++ compilation.
if(Python_Interpreter_FOUND)
    execute_process(
        COMMAND "${QT_INTERNAL_ROS2_BRIDGE_PYTHON}"
            "${CMAKE_CURRENT_SOURCE_DIR}/../../config.tests/urdfviewer_python/check_deps.py"
        RESULT_VARIABLE _urdfviewer_py_result
        OUTPUT_QUIET
        ERROR_QUIET
    )
    if(_urdfviewer_py_result EQUAL 0)
        set(HAVE_URDFVIEWER_PYTHON_DEPS TRUE)
    else()
        set(HAVE_URDFVIEWER_PYTHON_DEPS FALSE)
    endif()
    unset(_urdfviewer_py_result)
else()
    set(HAVE_URDFVIEWER_PYTHON_DEPS FALSE)
endif()

# Qt's feature system caches FEATURE_ros2_urdfviewer after the first auto-detection and
# treats it as a user-provided value on subsequent runs. This prevents the feature from
# being re-evaluated when Python packages are installed or removed between runs. To work
# around this, we track the previous detection result and reset FEATURE_ros2_urdfviewer
# from the cache whenever Python availability changes, so the feature re-evaluates
# automatically.
if(NOT "${HAVE_URDFVIEWER_PYTHON_DEPS}" STREQUAL "${_qt_ros2_urdfviewer_prev_python_deps}")
    set(_qt_ros2_urdfviewer_prev_python_deps "${HAVE_URDFVIEWER_PYTHON_DEPS}"
        CACHE INTERNAL "Previous ros2-urdfviewer Python deps detection result" FORCE)
    unset(FEATURE_ros2_urdfviewer CACHE)
endif()



#### Features

qt_feature("ros2-bridge-python" PRIVATE
    LABEL "python"
    CONDITION Python_Interpreter_FOUND
)

qt_feature("ros2-urdfviewer" PRIVATE
    LABEL "urdfviewer tool"
    PURPOSE "Builds the urdfviewer URDF-to-Qt-Quick3D/ROS2 importer GUI tool."
    CONDITION QT_FEATURE_ros2_bridge_python AND HAVE_URDFVIEWER_PYTHON_DEPS
)

qt_configure_add_summary_section(NAME "Qt Ros2 Bridge")
qt_configure_add_summary_entry(ARGS "ros2-urdfviewer")
qt_configure_end_summary_section()
qt_configure_add_report_entry(
    TYPE WARNING
    MESSAGE "urdfviewer will not be built: Python 3 with packages 'urdf_parser_py' and 'jinja2' is required."
    CONDITION NOT QT_FEATURE_ros2_urdfviewer
)
