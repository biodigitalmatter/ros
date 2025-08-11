from pathlib import Path
import sys
from threading import Event, Thread

import launch
import launch_pytest
import launch_ros
import pytest
import rclpy
from rclpy.node import Node

from geometry_msgs.msg import PoseStamped


@pytest.fixture
def rosbag_path():
    here = Path(__file__).parent

    path_ = here / "fixtures" / "sample_calibration_video" / "rosbag"

    datapath = path_ / "rosbag_0.mcap"

    if not datapath.exists():
        raise RuntimeError("rosbag not found, check README.md on how to create")

    return path_


@launch_pytest.fixture
def generate_test_description(rosbag_path):
    node_path = Path(__file__).parents[2] / "chess_vision" / "charuco_tracker_node.py"
    print(f"{node_path=}")
    node = launch_ros.actions.Node(
        executable=sys.executable,
        arguments=[str(node_path), "--ros-args", "--log-level", "DEBUG"],
        name="charuco_tracker",
        parameters=[{"board_name": "sample_calibration_video", "rectified": True}],
        remappings=[
            (
                "/topic_video",
                "/image_raw",
            )
        ],
        additional_env={"PYTHONUNBUFFERED": "1"},  # dont buffer stdout stderr
        output="screen",
    )
    bag_play = launch.actions.ExecuteProcess(
        cmd=[
            "ros2",
            "bag",
            "play",
            "--disable-keyboard-controls",
            "--rate",
            "1",
            "--loop",
            str(rosbag_path),
        ],
        output="screen",
    )
    return launch.LaunchDescription(
        [node, bag_play, launch_pytest.actions.ReadyToTest()]
    )


# https://github.com/ros2/launch/blob/jazzy/launch_pytest/test/launch_pytest/examples/check_node_msgs.py
@pytest.mark.launch(fixture=generate_test_description)
def test_check_if_msgs_published():
    rclpy.init()

    try:
        node = MakeTestNode("test_node")
        node.start_subscriber()
        msgs_received_flag = node.msg_event_object.wait(timeout=5.0)
        assert msgs_received_flag, "Did not receive msgs !"
    finally:
        rclpy.shutdown()


class MakeTestNode(Node):
    def __init__(self, name="test_node"):
        super().__init__(name)
        self.msg_event_object = Event()

    def start_subscriber(self):
        self.subscription = self.create_subscription(
            PoseStamped, "charuco_pose", self.subscriber_callback, 10
        )

        self.ros_spin_thread = Thread(
            target=lambda node: rclpy.spin(node), args=(self,)
        )
        self.ros_spin_thread.start()

    def subscriber_callback(self, data):
        self.msg_event_object.set()
