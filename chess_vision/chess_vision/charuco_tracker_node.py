import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Image, CameraInfo
from geometry_msgs.msg import PoseStamped

from cv_bridge import CvBridge
import cv2
import cv2.aruco as aruco
import numpy as np
from scipy.spatial.transform import Rotation as R


class CharucoTracker(Node):
    def __init__(self):
        super().__init__("charuco_tracker")
        self.declare_parameter("board_type", "standard")
        self.board_type = (
            self.get_parameter("board_type").get_parameter_value().string_value
        )
        # Hardcoded ChArUco boards
        self.boards = {
            "standard": aruco.CharucoBoard_create(
                squaresX=5,
                squaresY=7,
                squareLength=0.04,
                markerLength=0.02,
                dictionary=aruco.getPredefinedDictionary(aruco.DICT_4X4_50),
            ),
        }

        self.board = self.boards[self.board_type]
        self.bridge = CvBridge()

        self.camera_info_sub = self.create_subscription(
            CameraInfo, "/camera/camera_info", self.camera_info_callback, 10
        )

        self.image_sub = self.create_subscription(
            Image, "/camera/image_raw", self.image_callback, 10
        )
        self.pose_pub = self.create_publisher(PoseStamped, "charuco_pose", 10)

    def camera_info_callback(self, msg: CameraInfo) -> None:
        self.camera_matrix = np.array(msg.k).reshape((3, 3))
        self.dist_coeffs = np.array(msg.d)
        self.get_logger().info("Camera calibration received and stored.")
        self.destroy_subscription(self.camera_info_sub)

    def image_callback(self, msg: Image) -> None:
        if not hasattr(self, "camera_matrix") or not hasattr(self, "dist_coeffs"):
            self.get_logger().warn("Camera calibration not yet received.")
            return

        frame = self.bridge.imgmsg_to_cv2(msg, desired_encoding="bgr8")
        corners, ids, _ = aruco.detectMarkers(frame, self.board.dictionary)
        if ids is not None:
            retval, charuco_corners, charuco_ids = aruco.interpolateCornersCharuco(
                corners, ids, frame, self.board
            )
            if retval > 0:
                success, rvec, tvec = aruco.estimatePoseCharucoBoard(
                    charuco_corners,
                    charuco_ids,
                    self.board,
                    self.camera_matrix,
                    self.dist_coeffs,
                )
                if success:
                    pose_msg = PoseStamped()

                    pose_msg.header.stamp = msg.header.stamp
                    pose_msg.header.frame_id = msg.header.frame_id

                    self.set_pose_from_cv(pose_msg, rvec, tvec)

                    self.pose_pub.publish(pose_msg)

    @staticmethod
    def set_pose_from_cv(
        pose_msg: PoseStamped, rvec: np.ndarray, tvec: np.array
    ) -> None:
        pose_msg.pose.position.x = float(tvec[0][0])
        pose_msg.pose.position.y = float(tvec[1][0])
        pose_msg.pose.position.z = float(tvec[2][0])

        rot_matrix, _ = cv2.Rodrigues(rvec)
        x, y, z, w = R.from_matrix(rot_matrix).as_quat()

        pose_msg.pose.orientation.x = x
        pose_msg.pose.orientation.y = y
        pose_msg.pose.orientation.z = z
        pose_msg.pose.orientation.w = w


def main(args=None):
    rclpy.init(args=args)
    node = CharucoTracker()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()


if __name__ == "__main__":
    main()
