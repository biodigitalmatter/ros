import typing

import rclpy
from rclpy.node import Node
from rclpy.qos import (
    QoSDurabilityPolicy,
    QoSHistoryPolicy,
    QoSProfile,
    QoSReliabilityPolicy,
)
from sensor_msgs.msg import Image

from elizabeth_perception_filters.depth_image_filters import clip_depth_image

DEPTH_IMAGE_QOS = QoSProfile(
    reliability=QoSReliabilityPolicy.RELIABLE,
    durability=QoSDurabilityPolicy.VOLATILE,
    history=QoSHistoryPolicy.KEEP_LAST,
    depth=10,
)


@typing.final
class DepthImageFilterNode(Node):
    def __init__(self):
        super().__init__("depth_image_filter")

        _ = self.declare_parameter("min_distance_m", value=0.2)
        _ = self.declare_parameter("max_distance_m", value=1.0)

        self.subscription = self.create_subscription(
            Image,
            "image_rect_raw",
            self.callback,
            DEPTH_IMAGE_QOS,
        )

        self.publisher = self.create_publisher(
            Image,
            "image_rect_filtered",
            DEPTH_IMAGE_QOS,
        )

        self.logger = self.get_logger()

    def callback(self, msg: Image) -> None:
        min_distance_m = float(self.get_parameter("min_distance_m").value)  # pyright: ignore[reportArgumentType, reportUnknownMemberType]
        max_distance_m = float(self.get_parameter("max_distance_m").value)  # pyright: ignore[reportUnknownMemberType, reportArgumentType]

        try:
            out = clip_depth_image(msg, min_distance_m, max_distance_m)
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
