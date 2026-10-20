from compas.geometry import Rotation, Transformation, Translation
from geometry_msgs.msg import Transform


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
