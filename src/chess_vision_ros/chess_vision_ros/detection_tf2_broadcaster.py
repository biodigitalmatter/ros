# SPDX-FileCopyrightText: (C) 2026 Anton Tetov Johansson <anton@tetov.se>
# SPDX-License-Identifier: Apache-2.0


import typing

import rclpy
from chess_vision_ros_interfaces.msg import CharucoDetection as CharucoDetectionMsg
from geometry_msgs.msg import TransformStamped
from rclpy.node import Node
from rclpy.qos import (
    QoSDurabilityPolicy,
    QoSHistoryPolicy,
    QoSProfile,
    QoSReliabilityPolicy,
)
from rclpy.subscription import Subscription
from tf2_ros import TransformBroadcaster

from chess_vision_ros.conversions import (
    transform_from_pose,
)

CAMERA_INFO_QOS = QoSProfile(
    reliability=QoSReliabilityPolicy.RELIABLE,
    durability=QoSDurabilityPolicy.VOLATILE,
    history=QoSHistoryPolicy.KEEP_LAST,
    depth=1,
)

IMAGE_QOS = QoSProfile(
    reliability=QoSReliabilityPolicy.RELIABLE,
    durability=QoSDurabilityPolicy.VOLATILE,
    history=QoSHistoryPolicy.KEEP_LAST,
    depth=1,
)

DETECTION_QOS = QoSProfile(
    reliability=QoSReliabilityPolicy.RELIABLE,
    durability=QoSDurabilityPolicy.VOLATILE,
    history=QoSHistoryPolicy.KEEP_LAST,
    depth=10,
)

MARKER_IMAGE_QOS = QoSProfile(
    reliability=QoSReliabilityPolicy.BEST_EFFORT,
    durability=QoSDurabilityPolicy.VOLATILE,
    history=QoSHistoryPolicy.KEEP_LAST,
    depth=1,
)


@typing.final
class DetectionTf2BroadCaster(Node):
    def __init__(self):
        super().__init__("detection_tf2_broadcaster")

        self.declare_parameter("child_frame_id", "charuco_detection")

        self.subscriber: Subscription = self.create_subscription(
            CharucoDetectionMsg, "charuco_detections", self.callback, DETECTION_QOS
        )

        self.tf_broadcaster = TransformBroadcaster(self)

        self.logger = self.get_logger()

        self.logger.info(
            "Node started, will publish detections with TF child_frame_id from node parameter child_frame_id."
        )

    def callback(self, msg: CharucoDetectionMsg):
        T = TransformStamped()

        T.header = msg.header

        T.header.stamp = msg.header.stamp
        T.child_frame_id = (
            self.get_parameter("child_frame_id").get_parameter_value().string_value
        )

        T.transform = transform_from_pose(msg.pose)

        self.tf_broadcaster.sendTransform(T)


def main(args: list[str] | None = None):
    rclpy.init(args=args)
    node = DetectionTf2BroadCaster()

    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == "__main__":
    main()
