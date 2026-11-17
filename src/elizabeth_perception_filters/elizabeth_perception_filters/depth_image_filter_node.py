import typing

import rclpy
from rclpy.node import Node
from rclpy.qos import qos_profile_sensor_data
from sensor_msgs.msg import Image

from elizabeth_perception_filters.clip_distance import clip_distance


@typing.final
class DepthImageFilterNode(Node):
    def __init__(self):
        super().__init__("depth_image_filter")

        self.declare_parameter("min_distance_m", value=0.2)
        self.declare_parameter("max_distance_m", value=1.0)

        self.subscription = self.create_subscription(
            Image,
            "image_rect_raw",
            self.callback,
            qos_profile_sensor_data,
        )

        self.publisher = self.create_publisher(
            Image,
            "image_rect_filtered",
            qos_profile_sensor_data,
        )

        self.logger = self.get_logger()

    def callback(self, msg: Image) -> None:
        min_distance_m = float(self.get_parameter("min_distance_m").value)
        max_distance_m = float(self.get_parameter("max_distance_m").value)

        try:
            out = clip_distance(msg, min_distance_m, max_distance_m)
        except ValueError as exc:
            _ = self.logger.warning(str(exc))
            return

        self.publisher.publish(out)


def main(args: list[str] | None = None):
    rclpy.init(args=args)

    node = DepthImageFilterNode()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()


if __name__ == "__main__":
    main()
