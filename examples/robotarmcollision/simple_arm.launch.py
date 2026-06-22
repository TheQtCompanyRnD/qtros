"""
simple_arm.launch.py
Launch joint_state_publisher_gui and robot_state_publisher for simple_arm.urdf.

Usage (source ROS 2 first):
    ros2 launch examples/robotarmcollision/simple_arm.launch.py

No colcon build or ROS package install required — the URDF is loaded
directly from the path relative to this launch file.

See: https://docs.ros.org/en/foxy/Tutorials/Intermediate/Launch/Creating-Launch-Files.html
"""

import os
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    urdf_path = os.path.join(os.path.dirname(__file__), "simple_arm.urdf")
    with open(urdf_path, "r") as f:
        robot_description = f.read()

    return LaunchDescription([
        # Broadcasts the robot's TF tree from the URDF.
        Node(
            package="robot_state_publisher",
            executable="robot_state_publisher",
            name="robot_state_publisher",
            parameters=[{"robot_description": robot_description}],
        ),
        # Interactive sliders that publish /joint_states.
        Node(
            package="joint_state_publisher_gui",
            executable="joint_state_publisher_gui",
            name="joint_state_publisher_gui",
            parameters=[{"robot_description": robot_description}],
        ),
    ])
