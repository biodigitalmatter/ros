import math

import numpy as np
from compas.geometry import Rotation, Translation, Vector
from geometry_msgs.msg import Transform

from chess_vision_ros.conversions import (
    pose_from_transformation,
    transformation_from_transform,
)


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


def test_pose_from_transformation_translation() -> None:

    Tr = Translation.from_vector([1, 2, 3])

    pose = pose_from_transformation(Tr)

    assert pose.position.x == 1.0
    assert pose.position.y == 2.0
    assert pose.position.z == 3.0

    assert pose.orientation.w == 1.0
    assert pose.orientation.x == 0.0
    assert pose.orientation.y == 0.0
    assert pose.orientation.z == 0.0


def test_pose_from_transformation_rotation() -> None:

    R = Rotation.from_axis_and_angle(Vector.Zaxis(), math.radians(90))

    pose = pose_from_transformation(R)

    assert pose.position.x == 0.0
    assert pose.position.y == 0.0
    assert pose.position.z == 0.0

    # 90 degrees around z
    assert pose.orientation.w == math.cos(math.pi / 4)
    assert pose.orientation.x == 0.0
    assert pose.orientation.y == 0.0
    assert pose.orientation.z == math.sin(math.pi / 4)


def test_pose_from_transformation_translation_and_rotation() -> None:
    v = Vector(1.0, 2.0, 3.0)
    Tr = Translation.from_vector(v)
    R = Rotation.from_axis_and_angle(Vector.Zaxis(), math.radians(90))

    T = R * Tr

    pose = pose_from_transformation(T)

    x, y, z = v
    # 90 degrees around z: x -> -y, y -> x, z -> z
    expected_vector = Vector(-y, x, z)
    actual_vector = Vector(pose.position.x, pose.position.y, pose.position.z)

    # to fix floating point precision errors
    assert expected_vector == actual_vector

    # 90 degrees around z
    assert pose.orientation.w == math.cos(math.pi / 4)
    assert pose.orientation.x == 0.0
    assert pose.orientation.y == 0.0
    assert pose.orientation.z == math.sin(math.pi / 4)
