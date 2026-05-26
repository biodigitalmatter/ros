from dataclasses import dataclass

import numpy as np
import numpy.typing as npt


@dataclass
class CameraCalibration:
    """Intrinsic"""

    """Intrinsic camera matrix for the raw (distorted) images. 3x3 matrix"""
    matrix: npt.NDArray[np.float64]
    """Distortion parameters. For "plumb_bob", the 5 parameters are: (k1, k2, t1, t2, k3)."""
    dist_coeffs: npt.NDArray[np.float64]

    @classmethod
    def create_dummy_intrinsics_from_image(cls, height: int, width: int):
        h = height
        w = width

        f = max(w, h)

        matrix = np.array(
            [
                [f, 0, w / 2.0],
                [0, f, h / 2.0],
                [0, 0, 1],
            ],
            dtype=np.float64,
        )
        dist_coeffs = np.zeros(5, dtype=np.float64)

        return cls(matrix, dist_coeffs)

    @classmethod
    def from_camera_info_msg_k_msg_d(
        cls, k: npt.NDArray[np.float64], d: npt.NDArray[np.float64]
    ):
        """Written for plumb_bob CameraInfo

        msg.k is an 1D array with 9 values"""
        assert len(k) == 9
        assert len(d) == 5  # PLUMB_BOB

        matrix = k.reshape((3, 3))
        dist_coeffs = np.asarray(d)

        return cls(matrix, dist_coeffs)
