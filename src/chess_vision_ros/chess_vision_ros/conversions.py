from compas.geometry import Rotation, Transformation, Translation
from geometry_msgs.msg import Pose, Transform


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
