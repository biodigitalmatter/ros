# SPDX-FileCopyrightText: (C) 2026 Anton Tetov Johansson <anton@tetov.se>
# SPDX-License-Identifier: Apache-2.0

import time

import launch
import launch_pytest
import launch_ros.actions
import numpy as np
import pytest
import rclpy
from sensor_msgs.msg import Image


@launch_pytest.fixture
def generate_test_description():
    return launch.LaunchDescription(
        [
            launch_ros.actions.Node(
                package="elizabeth_perception_filters",
                executable="depth_image_filter_node",
                parameters=[{"min_distance_m": 0.2, "max_distance_m": 1.0}],
            ),
            launch_pytest.actions.ReadyToTest(),
        ]
    )


@pytest.fixture
def ros_node(request):
    rclpy.init()
    node = rclpy.create_node(f"test_{request.node.name}")

    try:
        yield node
    finally:
        node.destroy_node()
        rclpy.shutdown()


@pytest.mark.launch(fixture=generate_test_description)
def test_filters_16uc1(ros_node) -> None:
    received: list[Image] = []

    pub = ros_node.create_publisher(Image, "image_rect_raw", 10)
    _ = ros_node.create_subscription(
        Image,
        "image_rect_filtered",
        lambda msg: received.append(msg),
        10,
    )

    msg = Image()
    msg.height = 1
    msg.width = 6
    msg.encoding = "16UC1"
    msg.step = msg.width * np.dtype(np.uint16).itemsize
    msg.data = np.array(
        [[0, 100, 200, 500, 1000, 1200]],
        dtype=np.uint16,
    ).tobytes()

    # wait for subscriber
    deadline = time.monotonic() + 5.0

    while time.monotonic() < deadline:
        rclpy.spin_once(ros_node, timeout_sec=0.1)

        if pub.get_subscription_count() > 0:
            break

    assert pub.get_subscription_count() > 0, (
        "depth_image_filter_node did not subscribe to image_rect_raw"
    )

    pub.publish(msg)

    deadline = time.monotonic() + 5.0

    while time.monotonic() < deadline:
        rclpy.spin_once(ros_node, timeout_sec=0.1)
        if received:
            break

    assert len(received), "No messages received"

    out = received[0]

    result = np.frombuffer(out.data, dtype=np.uint16).reshape(
        out.height,
        out.width,
    )

    np.testing.assert_array_equal(
        result,
        np.array([[0, 0, 200, 500, 1000, 0]], dtype=np.uint16),
    )
