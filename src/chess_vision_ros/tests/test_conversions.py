import math
from random import random

import numpy as np
from compas.geometry import Rotation, Transformation, Translation, Vector
from geometry_msgs.msg import Pose, Transform

from chess_vision_ros.conversions import (
    pose_from_transformation,
    transform_from_pose,
    transformation_from_transform,
)


def random_vector() -> Vector:
    return Vector(*[random() * 2 - 1 for _ in range(3)])


def random_rotation() -> Rotation:
    angle = math.radians(random() * 360)
    return Rotation.from_axis_and_angle(random_vector(), angle)


def random_transformation() -> Transformation:
    return Translation.from_vector(random_vector() * 100) * random_rotation()


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


def test_transform_from_pose():
    for _ in range(10):
        x, y, z = random_vector() * 100
        qw, qx, qy, qz = random_rotation().quaternion

        pose = Pose()
        pose.position.x = x
        pose.position.y = y
        pose.position.z = z

        pose.orientation.w = qw
        pose.orientation.x = qx
        pose.orientation.y = qy
        pose.orientation.z = qz

        expected_transform = Transform()

        expected_transform.translation.x = x
        expected_transform.translation.y = y
        expected_transform.translation.z = z

        expected_transform.rotation.w = qw
        expected_transform.rotation.x = qx
        expected_transform.rotation.y = qy
        expected_transform.rotation.z = qz

        assert expected_transform == transform_from_pose(pose)


def test_roundtrip_transformation_transform_pose():
    for _ in range(10):
        transformation = random_transformation()
        pose = pose_from_transformation(transformation)
        transform = transform_from_pose(pose)

        assert transformation == transformation_from_transform(transform)
