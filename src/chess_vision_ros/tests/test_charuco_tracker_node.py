# SPDX-FileCopyrightText: (C) 2026 Anton Tetov Johansson <anton@tetov.se>
# SPDX-License-Identifier: Apache-2.0

import os
import typing
from pathlib import Path
from threading import Event, Thread

import launch
import launch_pytest
import launch_ros
import pytest
import rclpy
from chess_vision_ros_interfaces.msg import CharucoDetection
from rclpy.executors import SingleThreadedExecutor
from rclpy.node import Node
from rclpy.qos import qos_profile_sensor_data
from sensor_msgs.msg import Image


@launch_pytest.fixture
def generate_test_description(charuco_rosbag_path: Path, sample_camera_info_path: Path):
    nodes = [
        launch_ros.actions.Node(
            package="chess_vision_ros",
            executable="charuco_tracker_node",
            name="charuco_tracker",
            parameters=[{"board_name": "sample_calibration_video_board"}],
            remappings=[
                (
                    "image_raw",
                    "/topic_video",
                )
            ],
        ),
        launch_ros.actions.Node(
            package="chess_vision_ros",
            executable="dummy_camera_info_publisher",
            parameters=[{"camera_info_file": str(sample_camera_info_path)}],
        ),
    ]
    bag_play = launch.actions.ExecuteProcess(
        cmd=[
            "ros2",
            "bag",
            "play",
            "--disable-keyboard-controls",
            "--rate",
            "1",
            "--loop",
            str(charuco_rosbag_path),
        ],
    )
    return launch.LaunchDescription(
        nodes
        + [
            bag_play,
            launch_pytest.actions.ReadyToTest(),
        ]
    )


@typing.final
class TrackerOutputSubscriber(Node):
    def __init__(self, name: str):
        super().__init__(name)

        self.topics = ["charuco_detection", "charuco_markers"]

        self.all_messages_received = Event()

        self.msg_counts = {name: 0 for name in self.topics}

        self.subscriptions_ = [
            self.create_subscription(
                CharucoDetection,
                "charuco_detection",
                self.charuco_detection_callback,
                10,
            ),
            self.create_subscription(
                Image,
                "charuco_markers",
                self.charuco_markers_callback,
                qos_profile_sensor_data,
            ),
        ]

        self.logger = self.get_logger()

        self.logger.info("started node")

    def _message_received(self, topic: str) -> None:
        self.msg_counts[topic] += 1

        if all(self.msg_counts.values()):
            self.all_messages_received.set()

    def charuco_detection_callback(self, data: CharucoDetection) -> None:
        self.logger.debug(f"{data=}", once=True)
        self._message_received("charuco_detection")

    def charuco_markers_callback(self, data: Image) -> None:
        self.logger.debug(f"{data=}", once=True)
        self._message_received("charuco_markers")


@pytest.fixture
def ros_node(request) -> typing.Iterator[TrackerOutputSubscriber]:
    rclpy.init()
    node = TrackerOutputSubscriber(f"test_{request.node.name}")

    executor = SingleThreadedExecutor()
    executor.add_node(node)

    spin_thread = Thread(target=executor.spin, daemon=False)

    spin_thread.start()

    try:
        yield node
    finally:
        executor.shutdown()
        spin_thread.join(timeout=20.0)

        if spin_thread.is_alive():
            pytest.fail("ROS executor thread did not stop")

        executor.remove_node(node)
        node.destroy_node()

        rclpy.shutdown()


# https://github.com/ros2/launch/blob/jazzy/launch_pytest/test/launch_pytest/examples/check_node_msgs.py
@pytest.mark.launch(fixture=generate_test_description)
@pytest.mark.skipif("CI" in os.environ, reason="Does not have bagfile")
@pytest.mark.filterwarnings("ignore:There is no current event loop")
def test_check_if_msgs_published(ros_node):
    assert ros_node.all_messages_received.wait(timeout=10.0), (
        f"Did not recieve expected messages: {ros_node.msg_counts}"
    )
