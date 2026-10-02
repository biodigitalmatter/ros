import math

import cv2 as cv
import numpy as np
import pytest
from compas.geometry import Frame, Rotation, Transformation, Vector
from numpy.testing import assert_allclose

from chess_vision.geometry import transformation_from_cv, transformation_to_cv


def test_transformation_from_cv_with_rotation_matrix() -> None:
    R = np.asarray(
        Rotation.from_axis_and_angle(Vector(0, 0, 1), math.pi / 2).matrix,
        dtype=np.float64,
    )[:3, :3]
    t = np.array([1.0, 2.0, 3.0], dtype=np.float64)

    T = transformation_from_cv(R, t)

    expected = Transformation.from_frame(Frame(point=[1, 2, 3]))

    expected = np.eye(4)
    expected[:3, :3] = R
    expected[:3, 3] = t

    assert_allclose(T.matrix, expected)


def test_transformation_from_cv_with_rotation_vector() -> None:
    rvec = np.array([0.0, 0.0, math.pi / 2], dtype=np.float64)
    t = np.array([[1.0], [2.0], [3.0]], dtype=np.float64)

    expected_R, _ = cv.Rodrigues(rvec)

    T = transformation_from_cv(rvec, t)

    expected = np.eye(4)
    expected[:3, :3] = expected_R
    expected[:3, 3] = t.reshape(3)

    assert_allclose(T.matrix, expected)


@pytest.mark.parametrize(
    "t",
    [
        np.array([1.0, 2.0, 3]),
        np.array([[1.0], [2.0], [3.0]]),
        np.array([[1.0, 2.0, 3.0]]),
    ],
)
def test_transformation_from_cv_accepts_translation_shapes(t) -> None:
    T = transformation_from_cv(np.eye(3), t)

    assert_allclose(np.asarray(T.matrix)[:3, 3], [1.0, 2.0, 3.0])


def test_transformation_to_cv() -> None:
    T = Transformation.from_frame(
        Frame.from_rotation(Rotation.from_axis_and_angle(Vector(0, 0, 1), math.pi / 2))
    )

    T.matrix[0][3] = 1.0
    T.matrix[1][3] = 2.0
    T.matrix[2][3] = 3.0

    R, t = transformation_to_cv(T)

    expected = np.asarray(T.matrix, dtype=np.float64)

    assert_allclose(R, expected[:3, :3])
    assert_allclose(t, expected[:3, 3])


def test_transformation_cv_round_trip() -> None:
    matrix = np.asarray(
        Rotation.from_axis_and_angle(Vector(1, 2, 3), math.pi / 3).matrix,
        dtype=np.float64,
    )
    matrix[:3, 3] = [
        4.0,
        5.0,
        6.0,
    ]

    expected = Transformation.from_matrix(matrix.tolist())

    R, t = transformation_to_cv(expected)
    actual = transformation_from_cv(R, t)

    assert_allclose(actual.matrix, expected.matrix)


def test_transformation_from_cv_rejects_invalid_rotation_shape() -> None:
    R = np.zeros((2, 2))
    t = np.array([1.0, 2.0, 3.0])

    with pytest.raises(ValueError, match="Expected rotation matrix or rotation vector"):
        transformation_from_cv(R, t)
