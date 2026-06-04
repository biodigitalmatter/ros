import cv2 as cv
import rclpy
from cv_bridge import CvBridge
from rclpy.node import Node
from sensor_msgs.msg import Image


class ArucoTracker(Node):
    def __init__(self):
        super().__init__("aruco_tracker")

        self.bridge = CvBridge()
        self.logger = self.get_logger()

        _ = self.declare_parameter("dictionary", "DICT_5X5_100")

        dictionary_name = (
            self.get_parameter("dictionary").get_parameter_value().string_value
        )

        if not hasattr(cv.aruco, dictionary_name):
            valid_dicts = [name for name in dir(cv.aruco) if name.startswith("DICT_")]
            raise ValueError(
                f"Unknown ArUco dictionary: {dictionary_name}. "
                f"Valid options include: {valid_dicts}"
            )

        dictionary_id = getattr(cv.aruco, dictionary_name)

        self.dictionary = cv.aruco.getPredefinedDictionary(dictionary_id)
        self.detector_params = cv.aruco.DetectorParameters()
        self.detector = cv.aruco.ArucoDetector(
            self.dictionary,
            self.detector_params,
        )

        self.sub = self.create_subscription(Image, "/image_raw", self.image_cb, 10)

        self.pub = self.create_publisher(Image, "/image_raw_markers", 10)

        self.logger.info("ArUco detector started")
        self.logger.info(f"Dictionary: {dictionary_name}")
        self.logger.info("Subscribing to: /image_raw")
        self.logger.info("Publishing to: /image_raw_markers")

    def image_cb(self, msg):
        frame = self.bridge.imgmsg_to_cv2(msg, desired_encoding="bgr8")

        corners, ids, _rejected = self.detector.detectMarkers(frame)

        if ids is not None:
            cv.aruco.drawDetectedMarkers(frame, corners, ids)
            detected_ids = ids.flatten().tolist()
            self.logger.info(f"Detected ArUco IDs: {detected_ids}")
        else:
            self.logger.info("No markers detected")

        out_msg = self.bridge.cv2_to_imgmsg(frame, encoding="bgr8")
        out_msg.header = msg.header

        self.pub.publish(out_msg)


def main(args=None):
    rclpy.init(args=args)
    node = ArucoTracker()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()


if __name__ == "__main__":
    main()
