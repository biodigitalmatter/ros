import typing

import numpy as np
import numpy.typing as npt
import rclpy
from cv_bridge import CvBridge
from geometry_msgs.msg import PoseStamped
from rclpy.node import Node
from rclpy.publisher import Publisher
from rclpy.subscription import Subscription
from sensor_msgs.msg import CameraInfo, Image

from chess_vision import CameraCalibration, ChArUcoBoard, ChArUcoTracker


@typing.final
class ChArUcoTrackerNode(Node):
    def __init__(self):
        super().__init__("charuco_tracker")

        _ = self.declare_parameter("board_name", "large")
        _ = self.declare_parameter("rectified", False)

        self._tracker: ChArUcoTracker | None = None
        self._camera_calibration: CameraCalibration | None = None

        self.bridge: CvBridge = CvBridge()

        self.camera_info_sub: Subscription = self.create_subscription(
            CameraInfo, "camera_info", self.camera_info_callback, 10
        )

        self.image_sub: Subscription = self.create_subscription(
            Image, "image_raw", self.image_callback, 10
        )

        self.pose_pub: Publisher = self.create_publisher(
            PoseStamped, "charuco_pose", 10
        )

        self.marker_img_pub: Publisher = self.create_publisher(
            Image, "charuco_markers", 10
        )

        self.logger = self.get_logger()

    @property
    def board_name(self) -> str:
        board_name = self.get_parameter("board_name").get_parameter_value().string_value  # pyright: ignore[reportUnknownMemberType, reportUnknownVariableType]

        if not isinstance(board_name, str):
            raise RuntimeError(f"Invalid board_name type: {board_name=}")

        return board_name

    @property
    def rectified(self):
        rectified = self.get_parameter("rectified").get_parameter_value().bool_value  # pyright: ignore[reportUnknownVariableType, reportUnknownMemberType]

        if not isinstance(rectified, bool):
            raise RuntimeError(f"Invalid rectified parameter type: {rectified=}")

        return rectified

    @property
    def tracker(self):
        if self._tracker is None:
            if self._camera_calibration is None:
                _ = self.logger.warning(
                    "Trying to set up chess_vision ChArUco tracker but camera_calibration is not set."
                )
                return
            else:
                board = ChArUcoBoard.from_board_parameters_dict(self.board_name)
                self._tracker = ChArUcoTracker(board, self._camera_calibration)
        return self._tracker

    def camera_info_callback(self, msg: CameraInfo) -> None:
        self._camera_calibration = CameraCalibration.from_camera_info_msg_k_msg_d(
            msg.k, msg.d
        )

        _ = self.logger.info("Camera calibration received and stored.")

        if self.camera_info_sub:
            _ = self.destroy_subscription(self.camera_info_sub)

    def image_callback(self, msg: Image) -> None:
        if self.tracker is None:
            if self.rectified:
                self._camera_calibration = (
                    CameraCalibration.create_dummy_intrinsics_from_image(
                        height=msg.height, width=msg.width
                    )
                )
                assert self.tracker is not None
            else:
                _ = self.logger.warning("Image gotten before camera info.")  # pyright: ignore[reportUnknownMemberType]
                return

        frame: npt.NDArray[np.uint8] = self.bridge.imgmsg_to_cv2(
            msg, desired_encoding="bgr8"
        )

        marked_frame, marker_ids, xform = self.tracker.detect_pose(frame)

        out_msg = self.bridge.cv2_to_imgmsg(
            marked_frame,
            encoding="bgr8",
        )

        out_msg.header = msg.header

        self.marker_img_pub.publish(out_msg)

        if marker_ids is not None:
            _ = self.logger.debug(
                f"Detected marker IDs: {marker_ids.flatten().tolist()}"
            )

        if xform is None:
            _ = self.logger.debug("No poses detected.")
            return

        pose_msg = PoseStamped()

        pose_msg.header.stamp = msg.header.stamp
        pose_msg.header.frame_id = msg.header.frame_id

        _, _, Ro, Tr, _ = xform.decomposed()

        x, y, z = Tr.translation_vector

        pose_msg.pose.position.x = x
        pose_msg.pose.position.y = y
        pose_msg.pose.position.z = z

        x, y, z, w = Ro.quaternion.xyzw

        pose_msg.pose.orientation.x = x
        pose_msg.pose.orientation.y = y
        pose_msg.pose.orientation.z = z
        pose_msg.pose.orientation.w = w

        self.pose_pub.publish(pose_msg)


def main(args: list[str] | None = None):
    rclpy.init(args=args)
    node = ChArUcoTrackerNode()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()


if __name__ == "__main__":
    main()
