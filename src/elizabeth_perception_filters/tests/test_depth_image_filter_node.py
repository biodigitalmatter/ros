import launch
import launch_ros.actions
import launch_testing.actions
import numpy as np
import pytest
import rclpy
from sensor_msgs.msg import Image


@pytest.mark.launch_test
def generate_test_description():
    return (
        launch.LaunchDescription(
            [
                launch_ros.actions.Node(
                    package="elizabeth_perception_filters",
                    executable="depth_image_filter_node",
                    parameters=[{"min_distance_m": 0.2, "max_distance_m": 1.0}],
                ),
                launch_testing.actions.ReadyToTest(),
            ]
        ),
        {},
    )


class TestDepthImageFilterLaunch:
    def test_filters_16uc1(self) -> None:
        rclpy.init()
        node = rclpy.create_node("test_depth_image_filter")

        received: list[Image] = []

        pub = node.create_publisher(Image, "image_rect_raw", 10)
        _ = node.create_subscription(
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

        try:
            pub.publish(msg)

            for _ in range(20):
                rclpy.spin_once(node, timeout_sec=0.1)
                if received:
                    break

            out = received[0]
            result = np.frombuffer(out.data, dtype=np.uint16).reshape(
                out.height,
                out.width,
            )

            np.testing.assert_array_equal(
                result,
                np.array([[0, 0, 200, 500, 1000, 0]], dtype=np.uint16),
            )

        finally:
            node.destroy_node()
            rclpy.shutdown()
