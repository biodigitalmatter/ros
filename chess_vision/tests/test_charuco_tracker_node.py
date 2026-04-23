from threading import Event

import launch
from launch.events import Shutdown
import launch_pytest
import launch_ros
import pytest
import rclpy
from rclpy.node import Node
from geometry_msgs.msg import PoseStamped


@launch_pytest.fixture
def generate_test_description(rosbag_path, calibration_yaml_path):
    nodes = [
        launch_ros.actions.Node(
            package="chess_vision",
            executable="charuco_tracker_node",
            name="charuco_tracker",
            parameters=[
                {"board_name": "sample_calibration_video_board", "rectified": True}
            ],
            remappings=[
                (
                    "image_raw",
                    "/topic_video",
                )
            ],
        ),
        launch_ros.actions.Node(
            package="chess_vision",
            executable="test_camera_info_publisher",
            parameters=[{"camera_info_file": str(calibration_yaml_path)}],
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
            str(rosbag_path),
        ],
    )
    return launch.LaunchDescription(
        nodes
        + [
            bag_play,
            launch_pytest.actions.ReadyToTest(),
            launch.actions.TimerAction(
                period=6.0,
                actions=[launch.actions.EmitEvent(event=Shutdown())],
            ),
        ]
    )


# https://github.com/ros2/launch/blob/jazzy/launch_pytest/test/launch_pytest/examples/check_node_msgs.py
@pytest.mark.launch(fixture=generate_test_description)
def test_check_if_msgs_published():
    rclpy.init()
    node = MakeTestNode("test_node")

    try:
        start_time = node.get_clock().now()

        timeout_sec = 5.0
        received = False

        while (node.get_clock().now() - start_time).nanoseconds < timeout_sec * 1e9:
            rclpy.spin_once(node, timeout_sec=0.1)

            if node.msg_event_object.is_set():
                received = True
                break

        assert received, "Did not receive msgs!"

    finally:
        node.destroy_node()
        rclpy.shutdown()


class MakeTestNode(Node):
    def __init__(self, name="test_node"):
        super().__init__(name)
        self.msg_event_object = Event()

        self.subscription = self.create_subscription(
            PoseStamped,
            "charuco_pose",
            self.subscriber_callback,
            10,
        )

    def subscriber_callback(self, data):
        self.msg_event_object.set()
