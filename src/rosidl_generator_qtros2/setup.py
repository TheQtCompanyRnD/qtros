# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

from setuptools import setup

package_name = 'rosidl_generator_qtros2'

setup(
    name=package_name,
    version='0.1.0',
    packages=[package_name],
    install_requires=['empy', 'rosidl-pycommon'],
    zip_safe=False,
    author='QtROS2 Team',
    author_email='dev@qtros2.org',
    maintainer='QtROS2 Team',
    maintainer_email='dev@qtros2.org',
    description='Generate Qt/QML C++ code from ROS 2 interface definitions',
    license='Apache-2.0',
    entry_points={
        'console_scripts': [
            'rosidl_generator_qtros2 = rosidl_generator_qtros2.__main__:main',
        ],
    },
)
