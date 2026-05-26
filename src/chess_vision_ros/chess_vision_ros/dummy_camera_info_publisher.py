import json
import pathlib
import typing

import rclpy
from rclpy.node import Node
from sensor_msgs.msg import CameraInfo


@typing.final
class DummyCameraInfoPublisher(Node):
    def __init__(self):
        super().__init__("dummy_camera_info_publisher")

        _ = self.declare_parameter("camera_info_file", "./calibration.yaml")

        camera_info_file = pathlib.Path(
            self.get_parameter("camera_info_file").get_parameter_value().string_value
        )

        with camera_info_file.open(mode="r") as fp:
            data = json.load(fp)

        self.msg = CameraInfo()
        self.msg.height = data["height"]
        self.msg.width = data["width"]
        self.msg.k = data["k"]
        self.msg.d = data["d"]
        self.msg.r = data["r"]
        self.msg.p = data["p"]
        self.msg.distortion_model = data["distortion_model"]
        self.msg.header.frame_id = "dummy_camera"

        self.pub = self.create_publisher(CameraInfo, "/camera_info", 10)
        self.timer = self.create_timer(0.05, self.publish)

    def publish(self):
        self.msg.header.stamp = self.get_clock().now().to_msg()
        self.pub.publish(self.msg)


def main():
    rclpy.init()
    node = DummyCameraInfoPublisher()
    rclpy.spin(node)
    rclpy.shutdown()
