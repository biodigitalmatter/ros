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

from chess_vision import ChArUcoBoard


@final
class CharucoTracker(Node):
    def __init__(self):
        super().__init__("charuco_tracker")

        _ = self.declare_parameter("board_name", "standard")
        _ = self.declare_parameter("rectified", False)

        self._board: ChArUcoBoard | None = None

        self.rectified = (
            self.get_parameter("rectified").get_parameter_value().bool_value
        )

        if not isinstance(self.rectified, bool):
            raise RuntimeError(f"Parameter rectified not bool: {self.rectified=}")

        self.bridge: CvBridge = CvBridge()

        if self.rectified:
            self.camera_info_sub = None
            self.camera_matrix = np.array(
                [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]], dtype=np.float64
            )
            self.dist_coeffs = np.zeros(shape=(5, 1), dtype=np.float64)

        else:
            self.camera_info_sub = self.create_subscription(
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

    def camera_info_callback(self, msg: CameraInfo) -> None:
        self.camera_matrix = np.array(msg.k).reshape((3, 3))
        self.dist_coeffs = np.array(msg.d)

        _ = self.logger.info("Camera calibration received and stored.")

        if self.camera_info_sub:
            _ = self.destroy_subscription(self.camera_info_sub)

    def image_callback(self, msg: Image) -> None:
        if not self.rectified:
            if not hasattr(self, "camera_matrix") or not hasattr(self, "dist_coeffs"):
                self.logger.warn("Camera calibration not yet received.")
                return

        frame = self.bridge.imgmsg_to_cv2(msg, desired_encoding="bgr8")

        # FIXME: temp fix
        if not hasattr(self, "camera_matrix"):
            self.camera_matrix = np.empty(shape=(3, 3))
            self.get_logger().warn(
                "Rectified was passed so setting camera matrix to empty array"
            )
        if not hasattr(self, "dist_coeffs"):
            self.camera_matrix = np.empty(shape=(3, 3))
            self.dist_coeffs = None
            self.get_logger().warn(
                "Rectified was passed so setting dist coeffs to None"
            )

        corners, ids, _ = aruco.detectMarkers(frame, self.board.dictionary)
        if ids is not None:
            retval, charuco_corners, charuco_ids = aruco.interpolateCornersCharuco(
                corners, ids, frame, self.board.board
            )
            if retval > 0:
                # https://docs.opencv.org/4.6.0/d9/d6a/group__aruco.html#ga21b51b9e8c6422a4bac27e48fa0a150b
                success, rvec, tvec = aruco.estimatePoseCharucoBoard(
                    charuco_corners,
                    charuco_ids,
                    self.board.board,
                    self.camera_matrix,
                    self.dist_coeffs,
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
