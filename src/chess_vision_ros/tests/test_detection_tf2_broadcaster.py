# SPDX-FileCopyrightText: (C) 2026 Anton Tetov Johansson <anton@tetov.se>
# SPDX-License-Identifier: Apache-2.0

import math
import time
import typing
from threading import Event, Thread

import launch
import launch_pytest
import launch_ros
import pytest
import rclpy
from chess_vision_ros_interfaces.msg import CharucoDetection as CharucoDetectionMsg
from compas.geometry import Rotation, Translation, Vector
from rclpy.executors import SingleThreadedExecutor
from rclpy.node import Node
from tf2_msgs.msg import TFMessage
from tf2_ros import Buffer, TransformListener

from chess_vision.charuco_tracker import ChArUcoDetection as ChArUcoDetectionPyObj
from chess_vision_ros.conversions import (
    ros_msg_from_charuco_detection,
    transform_from_pose,
)

CHILD_FRAME_ID = "charuco_detection"


@launch_pytest.fixture
def generate_test_description():
    return launch.LaunchDescription(
        [
            launch_ros.actions.Node(
                package="chess_vision_ros",
                executable="detection_tf2_broadcaster",
                name="detection_tf2_broadcaster",
                parameters=[{"child_frame_id": CHILD_FRAME_ID}],
            ),
            launch_pytest.actions.ReadyToTest(),
        ]
    )


@typing.final
class DetectionTf2BroadcasterTestNode(Node):
    def __init__(self, name: str):
        super().__init__(name)

        self.target_frame = "charuco_frame"

        self.tf_buffer = Buffer()
        self.tf_listener = TransformListener(self.tf_buffer, self)
        self.tf_error: Exception | None = None
        self.tf_match_event = Event()

        self.detection_subscriber = self.create_subscription(
            CharucoDetectionMsg,
            "charuco_detections",
            self.detection_callback,
            10,
        )

        self.detection_publisher = self.create_publisher(
            CharucoDetectionMsg,
            "charuco_detections",
            10,
        )
        self.tf_sub = self.create_subscription(TFMessage, "/tf", self.tf_callback, 10)
        self.tf_static_sub = self.create_subscription(
            TFMessage, "/tf_static", self.tf_callback, 10
        )

        self.logger = self.get_logger()

        self.logger.info("started node")

    def detection_callback(self, data: CharucoDetectionMsg) -> None:
        self.logger.info(f"{data=}", once=True)

        target_frame = data.header.frame_id
        source_frame = CHILD_FRAME_ID

        future = self.tf_buffer.wait_for_transform_async(
            target_frame, source_frame, data.header.stamp
        )

        def on_transform_ready(future):
            try:
                future.result()  # Propagate lookup failures.
                transform = self.tf_buffer.lookup_transform(
                    target_frame, source_frame, data.header.stamp
                )
                # simple equality check works since it copies input directly
                assert transform_from_pose(data.pose) == transform.transform
                self.tf_match_event.set()
            except Exception as ex:
                self.tf_error = ex
                self.tf_match_event.set()

        future.add_done_callback(on_transform_ready)

    def tf_callback(self, msg: TFMessage) -> None:
        for transform in msg.transforms:
            self.get_logger().info(
                f"{transform.header.frame_id} -> {transform.child_frame_id}: "
                f"{transform.transform}"
            )

    def wait_for_broadcaster(self, timeout_sec: float = 10.0) -> None:
        deadline = time.monotonic() + timeout_sec

        while time.monotonic() < deadline:
            subscriptions = self.get_subscriptions_info_by_topic("charuco_detections")
            if any(
                endpoint.node_name == "detection_tf2_broadcaster"
                for endpoint in subscriptions
            ):
                return
            time.sleep(0.01)

        pytest.fail("Broadcaster did not subscribe to charuco_detections")


@pytest.fixture
def ros_node(request) -> typing.Iterator[DetectionTf2BroadcasterTestNode]:
    rclpy.init()
    node = DetectionTf2BroadcasterTestNode(f"test_tf2_subscriber_{request.node.name}")

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

        rclpy.try_shutdown()


@pytest.mark.filterwarnings("ignore:There is no current event loop")
@pytest.mark.launch(fixture=generate_test_description)
def test_check_detection_tf_broadcasted(ros_node):

    ros_node.wait_for_broadcaster()

    transformation = Translation.from_vector([1, 2, 3]) * Rotation.from_axis_and_angle(
        Vector.Zaxis(), math.radians(270)
    )
    msg = ros_msg_from_charuco_detection(
        ChArUcoDetectionPyObj(transformation, 25, 10, 0.1)
    )
    msg.header.stamp = ros_node.get_clock().now().to_msg()
    msg.header.frame_id = "camera_frame"

    ros_node.detection_publisher.publish(msg)

    assert ros_node.tf_match_event.wait(timeout=10.0), "Transform lookup timed out."
    assert ros_node.tf_error is None, f"Transform lookup failed: {ros_node.tf_error}"
