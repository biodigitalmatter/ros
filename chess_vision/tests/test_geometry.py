import math

import cv2 as cv
import numpy as np
import pytest
from chess_vision.geometry import xform_from_cv
from compas.geometry import Transformation


def test_xform_from_cv_with_rotation_matrix() -> None:
    angle = math.pi / 2
    R = np.array(
        [
            [math.cos(angle), -math.sin(angle), 0],
            [math.sin(angle), math.cos(angle), 0],
            [0, 0, 1],
        ],
        dtype=np.float64,
    )
    t = np.array([1, 2, 3], dtype=np.float64)

    T_actual = xform_from_cv(R, t)

    M = np.eye(4, dtype=np.float64)
    M[:3, :3] = R
    M[:3, 3] = t

    T_expected = Transformation.from_matrix(M.tolist())

    assert T_actual == T_expected


def test_xform_from_cv_with_rodrigues_vector() -> None:
    rvec = np.array([0, 0, math.pi / 2], dtype=np.float64)
    t = np.array([[1], [2], [3]], dtype=np.float64)

    expected_R, _ = cv.Rodrigues(rvec)

    M = np.eye(4, dtype=np.float64)
    M[:3, :3] = expected_R
    M[:3, 3] = t.reshape(3)

    T_expected = Transformation.from_matrix(M.tolist())
    T_actual = xform_from_cv(rvec, t)

    assert T_actual == T_expected


def test_xform_from_cv_rejects_invalid_rotation_shape() -> None:
    R = np.zeros((2, 2), dtype=np.float64)
    t = np.array([1.0, 2.0, 3.0], dtype=np.float64)

    with pytest.raises(ValueError):
        xform_from_cv(R, t)
