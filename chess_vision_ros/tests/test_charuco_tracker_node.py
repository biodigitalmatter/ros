from threading import Event, Thread
import typing

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
# @pytest.mark.skip(reason="Something makes this run forever")
@pytest.mark.launch(fixture=generate_test_description)
def test_check_if_msgs_published():
    rclpy.init()

    try:
        node = MakeTestNode("test_node", min_recv_msgs=50)
        msgs_received_flag = node.msg_event_object.wait(timeout=5.0)
        assert msgs_received_flag, "Did not receive msgs!"
    finally:
        rclpy.shutdown()


@typing.final
class MakeTestNode(Node):
    def __init__(self, name="test_node", min_recv_msgs=10):
        super().__init__(name)

        self.min_recv_msgs = min_recv_msgs

        self.msg_event_object = Event()

        self.subscription = self.create_subscription(
            PoseStamped,
            "charuco_pose",
            self.subscriber_callback,
            10,
        )

        self.ros_spin_thread = Thread(
            target=lambda: rclpy.spin(self),
            # doesnt keep test waiting after timeout
            daemon=True,
        )
        self.ros_spin_thread.start()

        self.logger = self.get_logger()

        self.logger.info("started node")

        self.msg_count = 0

    def subscriber_callback(self, data):
        self.logger.info(f"{data=}", once=True)

        self.logger.info(
            f"{self.msg_count=}",
        )

        if self.msg_count >= self.min_recv_msgs:
            self.msg_event_object.set()

        self.msg_count += 1
