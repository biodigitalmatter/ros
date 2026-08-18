# SPDX-FileCopyrightText: (C) 2026 Anton Tetov Johansson <anton@tetov.se>
# SPDX-License-Identifier: Apache-2.0

import time
import typing

import launch
import launch_pytest
import launch_ros.actions
import pytest
import rclpy
from rclpy.node import Node
from std_srvs.srv import Trigger
from world_builder.srv import SaveVolume


@launch_pytest.fixture(scope="module")
def generate_test_description():
    return launch.LaunchDescription(
        [
            launch_ros.actions.Node(
                package="world_builder",
                executable="world_builder_node",
                name="world_builder",
                parameters=[
                    {
                        "world_frame": "world",
                        "voxel_size": 0.005,
                        "truncation_distance": 0.02,
                    }
                ],
            ),
            launch_pytest.actions.ReadyToTest(),
        ]
    )


@typing.final
class MakeTestNode(Node):
    def __init__(self, name: str = "test_node"):
        super().__init__(name)


@pytest.mark.launch(fixture=generate_test_description)
def test_world_builder_appears():
    rclpy.init()

    node = MakeTestNode("node_appears")

    try:
        deadline = time.monotonic() + 5.0

        while time.monotonic() < deadline:
            rclpy.spin_once(node, timeout_sec=0.1)

            if "world_builder" in node.get_node_names():
                return

        pytest.fail("world_builder node did not appear")
    finally:
        node.destroy_node()
        rclpy.shutdown()


@pytest.mark.launch(fixture=generate_test_description)
@pytest.mark.parametrize(
    "service_name,service_type", [("save", SaveVolume), ("clear", Trigger)]
)
def test_clear_service_exists(service_name, service_type):
    rclpy.init()

    node = MakeTestNode(f"{service_name}_srv_appears")

    try:
        client = node.create_client(service_type, f"/world_builder/{service_name}")

        assert client.wait_for_service(timeout_sec=5.0)
    finally:
        node.destroy_node()
        rclpy.shutdown()
