from typing import final
import rclpy
from rclpy.node import Node
from rclpy.publisher import Publisher
from rclpy.subscription import Subscription
from sensor_msgs.msg import Image, CameraInfo
from geometry_msgs.msg import PoseStamped

from cv_bridge import CvBridge
from cv2 import aruco, Rodrigues
import numpy as np
from scipy.spatial.transform import Rotation as R
import numpy.typing as npt

from chess_vision import CameraCalibration, ChArUcoBoard


@final
class CharucoTracker(Node):
    def __init__(self):
        super().__init__("charuco_tracker")

        _ = self.declare_parameter("board_name", "standard")
        _ = self.declare_parameter("rectified", False)

        self._board: ChArUcoBoard | None = None
        self.camera_calibration: CameraCalibration | None = None

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

        self.logger = self.get_logger()

    @property
    def board_name(self) -> str:
        board_name = self.get_parameter("board_name").get_parameter_value().string_value  # pyright: ignore[reportUnknownMemberType, reportUnknownVariableType]

        if not isinstance(board_name, str):
            raise RuntimeError(f"Invalid board_name type: {board_name=}")

        return board_name

    @property
    def board(self):
        return ChArUcoBoard.from_board_parameters_dict(self.board_name)

    @property
    def rectified(self):
        rectified = self.get_parameter("rectified").get_parameter_value().bool_value  # pyright: ignore[reportUnknownVariableType, reportUnknownMemberType]

        if not isinstance(rectified, bool):
            raise RuntimeError(f"Invalid rectified parameter type: {rectified=}")

        return rectified

    def camera_info_callback(self, msg: CameraInfo) -> None:
        self.camera_calibration = CameraCalibration.from_camera_info_msg_k_msg_d(
            msg.k, msg.d
        )

        _ = self.logger.info("Camera calibration received and stored.")

        if self.camera_info_sub:
            _ = self.destroy_subscription(self.camera_info_sub)

    def image_callback(self, msg: Image) -> None:
        if self.camera_calibration is None:
            if self.rectified:
                self.camera_calibration = (
                    CameraCalibration.create_dummy_intrinsics_from_image(
                        height=msg.height, width=msg.width
                    )
                )
            else:
                self.logger.warn("Camera calibration not yet received.")
                return

        frame = self.bridge.imgmsg_to_cv2(msg, desired_encoding="bgr8")

        corners, ids, _ = aruco.detectMarkers(frame, self.board.dictionary)
        if ids is not None:
            retval, charuco_corners, charuco_ids = aruco.interpolateCornersCharuco(
                corners, ids, frame, self.board.board
            )
            if retval > 0:
                success, rvec, tvec = aruco.estimatePoseCharucoBoard(
                    charuco_corners,
                    charuco_ids,
                    self.board.board,
                    self.camera_calibration.matrix,
                    self.camera_calibration.dist_coeffs,
                    np.empty(1),
                    np.empty(1),
                )
                if success:
                    pose_msg = PoseStamped()

                    pose_msg.header.stamp = msg.header.stamp
                    pose_msg.header.frame_id = msg.header.frame_id

                    self.set_pose_from_cv(pose_msg, rvec, tvec)

                    self.pose_pub.publish(pose_msg)

    @staticmethod
    def set_pose_from_cv(
        pose_msg: PoseStamped,
        rvec: npt.NDArray[np.float64],
        tvec: npt.NDArray[np.float64],
    ) -> None:
        pose_msg.pose.position.x = float(tvec[0][0])
        pose_msg.pose.position.y = float(tvec[1][0])
        pose_msg.pose.position.z = float(tvec[2][0])

        rot_matrix, _ = Rodrigues(rvec)
        x, y, z, w = R.from_matrix(rot_matrix).as_quat()

        pose_msg.pose.orientation.x = x
        pose_msg.pose.orientation.y = y
        pose_msg.pose.orientation.z = z
        pose_msg.pose.orientation.w = w


def main(args: list[str] | None = None):
    rclpy.init(args=args)
    node = CharucoTracker()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()


if __name__ == "__main__":
    main()
