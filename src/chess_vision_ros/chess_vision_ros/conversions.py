from chess_vision_ros_interfaces.msg import CharucoDetection as CharucoDetectionMsg
from compas.geometry import Rotation, Transformation, Translation
from geometry_msgs.msg import Pose, Transform

from chess_vision.charuco_tracker import ChArUcoDetection as ChArUcoDetectionPyObj


def transformation_from_transform(transform: Transform) -> Transformation:
    translation = Translation.from_vector(
        [
            transform.translation.x,
            transform.translation.y,
            transform.translation.z,
        ]
    )

    rotation = Rotation.from_quaternion(
        [
            transform.rotation.w,
            transform.rotation.x,
            transform.rotation.y,
            transform.rotation.z,
        ]
    )

    return translation * rotation


def pose_from_transformation(transformation: Transformation) -> Pose:
    msg = Pose()

    _, _, Ro, Tr, _ = transformation.decomposed()

    x, y, z = Tr.translation_vector

    msg.position.x = x
    msg.position.y = y
    msg.position.z = z

    x, y, z, w = Ro.quaternion.xyzw

    msg.orientation.x = x
    msg.orientation.y = y
    msg.orientation.z = z
    msg.orientation.w = w

    return msg


def ros_msg_from_charuco_detection(
    detection: ChArUcoDetectionPyObj,
) -> CharucoDetectionMsg:
    msg = CharucoDetectionMsg()

    msg.pose = pose_from_transformation(detection.transformation)

    msg.marker_count = detection.marker_count
    msg.corner_count = detection.corner_count
    msg.reprojection_error_px = detection.reprojection_error_px

    return msg
