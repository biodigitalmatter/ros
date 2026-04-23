import rclpy
from rclpy.node import Node
from sensor_msgs.msg import CameraInfo
import yaml


class CameraInfoPublisher(Node):
    def __init__(self):
        super().__init__("camera_info_publisher")

        yaml_path = self.declare_parameter("camera_info_file").value

        with open(yaml_path, "r") as f:
            data = yaml.safe_load(f)

        self.msg = CameraInfo()
        self.msg.width = data["image_width"]
        self.msg.height = data["image_height"]
        self.msg.k = data["camera_matrix"]["data"]
        self.msg.d = data["distortion_coefficients"]["data"]
        self.msg.r = data["rectification_matrix"]["data"]
        self.msg.p = data["projection_matrix"]["data"]
        self.msg.distortion_model = data["distortion_model"]
        self.msg.header.frame_id = data["camera_name"]

        self.pub = self.create_publisher(CameraInfo, "/camera_info", 10)
        self.timer = self.create_timer(0.05, self.publish)

    def publish(self):
        self.msg.header.stamp = self.get_clock().now().to_msg()
        self.pub.publish(self.msg)


def main():
    rclpy.init()
    node = CameraInfoPublisher()
    rclpy.spin(node)
    rclpy.shutdown()
