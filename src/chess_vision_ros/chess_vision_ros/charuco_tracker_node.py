import typing

import rclpy
from chess_vision_ros_interfaces.msg import CharucoDetection as CharucoDetectionMsg
from cv_bridge import CvBridge
from rclpy.node import Node
from rclpy.publisher import Publisher
from rclpy.qos import (
    QoSDurabilityPolicy,
    QoSHistoryPolicy,
    QoSProfile,
    QoSReliabilityPolicy,
)
from rclpy.subscription import Subscription
from sensor_msgs.msg import CameraInfo, Image

from chess_vision.camera_calibration import CameraCalibration
from chess_vision.charuco_board import ChArUcoBoard
from chess_vision.charuco_tracker import ChArUcoTracker, ImageU8
from chess_vision_ros.conversions import (
    ros_msg_from_charuco_detection,
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
class ChArUcoTrackerNode(Node):
    def __init__(self):
        super().__init__("charuco_tracker")

        _ = self.declare_parameter("board_name", "large")
        _ = self.declare_parameter("rectified", False)
        _ = self.declare_parameter("target_frame_id", "charuco")
        _ = self.declare_parameter("publish_tf", True)

        self._tracker: ChArUcoTracker | None = None
        self._camera_calibration: CameraCalibration | None = None

        self.bridge: CvBridge = CvBridge()

        self.camera_info_sub: Subscription = self.create_subscription(
            CameraInfo, "camera_info", self.camera_info_callback, CAMERA_INFO_QOS
        )

        self.image_sub: Subscription = self.create_subscription(
            Image, "image_raw", self.image_callback, IMAGE_QOS
        )

        self.detection_pub: Publisher = self.create_publisher(
            CharucoDetectionMsg,
            "charuco_detection",
            DETECTION_QOS,
        )

        self.marker_img_pub: Publisher = self.create_publisher(
            Image, "charuco_markers", MARKER_IMAGE_QOS
        )

        self.logger = self.get_logger()

    def _get_ros_parameter_bool(self, name: str) -> bool:
        value = self.get_parameter(name).get_parameter_value().bool_value

        if not isinstance(value, bool):
            raise RuntimeError(f"Invalid {name} type: {type(value)}")

        return value

    def _get_ros_parameter_str(self, name: str) -> str:
        value = self.get_parameter(name).get_parameter_value().string_value

        if not isinstance(value, str):
            raise RuntimeError(f"Invalid {name} type: {type(value)}")

        return value

    @property
    def tracker(self) -> ChArUcoTracker | None:
        if self._tracker is None and self._camera_calibration is not None:
            board_name = self._get_ros_parameter_str("board_name")
            board = ChArUcoBoard.from_board_parameters_dict(board_name)

            self._tracker = ChArUcoTracker(
                board,
                self._camera_calibration,
            )

        return self._tracker

    def camera_info_callback(self, msg: CameraInfo) -> None:
        self._camera_calibration = CameraCalibration.from_camera_info_msg_k_msg_d(
            msg.k, msg.d
        )

        _ = self.logger.info("Camera calibration received and stored.")

        if self.camera_info_sub:
            _ = self.destroy_subscription(self.camera_info_sub)

    def image_callback(self, msg: Image) -> None:
        self.logger.info("First image received", once=True)

        tracker = self.tracker

        if tracker is None:
            if not self._get_ros_parameter_bool("rectified"):
                self.logger.warning("Image received before camera info.", once=True)
                return
            self._camera_calibration = (
                CameraCalibration.create_dummy_intrinsics_from_image(
                    height=msg.height, width=msg.width
                )
            )
            tracker = self.tracker
            assert self.tracker is not None

        self.logger.info("Tracker set up", once=True)

        frame: ImageU8 = self.bridge.imgmsg_to_cv2(msg, desired_encoding="bgr8")

        marked_frame, detection = tracker.detect_pose(frame)

        self.logger.info("detect_pose returned", once=True)

        if detection is not None:
            self.logger.debug(
                f"Detected ChArUco: "
                f"{detection.marker_count} markers, "
                f"{detection.corner_count} corners, "
                f"{detection.reprojection_error_px:.2f} px"
            )

            detection_msg = ros_msg_from_charuco_detection(detection)
            detection_msg.header = msg.header
            detection_msg.child_frame_id = self._get_ros_parameter_str(
                "target_frame_id"
            )

            self.detection_pub.publish(detection_msg)

        marked_frame_msg = self.bridge.cv2_to_imgmsg(
            marked_frame,
            encoding="bgr8",
        )
        marked_frame_msg.header = msg.header

        self.marker_img_pub.publish(marked_frame_msg)


def main(args: list[str] | None = None):
    rclpy.init(args=args)
    node = ChArUcoTrackerNode()

    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == "__main__":
    main()
