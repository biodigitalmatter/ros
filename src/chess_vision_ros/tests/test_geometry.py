import math

import numpy as np
from geometry_msgs.msg import Transform

from chess_vision_ros.geometry import transformation_from_transform


def test_transformation_from_transform_translation() -> None:
    transform = Transform()

    transform.translation.x = 1.0
    transform.translation.y = 2.0
    transform.translation.z = 3.0
    transform.rotation.w = 1.0

    T = transformation_from_transform(transform)

    expected = np.array([
        [1.0, 0.0, 0.0, 1.0],
        [0.0, 1.0, 0.0, 2.0],
        [0.0, 0.0, 1.0, 3.0],
        [0.0, 0.0, 0.0, 1.0],
    ])  # fmt: skip

    np.testing.assert_allclose(T.matrix, expected)


def test_transformation_from_transform_rotation() -> None:
    transform = Transform()

    # 90 degrees around z
    transform.rotation.z = math.sin(math.pi / 4)
    transform.rotation.w = math.cos(math.pi / 4)

    transformation = transformation_from_transform(transform)

    expected = np.array([
            [0.0, -1.0, 0.0, 0.0],
            [1.0,  0.0, 0.0, 0.0],
            [0.0,  0.0, 1.0, 0.0],
            [0.0,  0.0, 0.0, 1.0],
        ])  # fmt: skip

    np.testing.assert_allclose(
        transformation.matrix,
        expected,
    )


def test_transformation_from_transform_translation_and_rotation() -> None:
    transform = Transform()

    transform.translation.x = 1.0
    transform.translation.y = 2.0
    transform.translation.z = 3.0

    # 90 degrees around z
    transform.rotation.z = math.sin(math.pi / 4)
    transform.rotation.w = math.cos(math.pi / 4)

    transformation = transformation_from_transform(transform)

    expected = np.array(
        [
            [0.0, -1.0, 0.0, 1.0],
            [1.0,  0.0, 0.0, 2.0],
            [0.0,  0.0, 1.0, 3.0],
            [0.0,  0.0, 0.0, 1.0],
        ]
    )  # fmt: skip

    np.testing.assert_allclose(
        transformation.matrix,
        expected,
    )
