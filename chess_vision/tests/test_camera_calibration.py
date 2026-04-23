import numpy as np

from chess_vision import CameraCalibration


def test_create_dummy_intrinsics_from_image() -> None:
    calibration = CameraCalibration.create_dummy_intrinsics_from_image(
        height=480, width=640
    )

    np.testing.assert_array_equal(
        calibration.matrix,
        np.array(
            [
                [640, 0, 320],
                [0, 640, 240],
                [0, 0, 1],
            ],
            dtype=np.float64,
        ),
    )

    np.testing.assert_array_equal(
        calibration.dist_coeffs,
        np.zeros(5, dtype=np.float64),
    )

    assert calibration.matrix.dtype == np.float64
    assert calibration.matrix.shape == (3, 3)

    assert calibration.dist_coeffs.shape == (5,)
    assert calibration.dist_coeffs.dtype == np.float64
