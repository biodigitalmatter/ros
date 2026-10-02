import cv2 as cv
import numpy as np
import numpy.typing as npt
from compas.geometry import Transformation


def transformation_from_cv(
    rotation: npt.ArrayLike, translation: npt.ArrayLike
) -> Transformation:

    rotation = np.asarray(rotation, dtype=np.float64)
    translation = np.asarray(translation, dtype=np.float64).reshape(3)

    if rotation.shape in ((3,), (3, 1), (1, 3)):
        rotation, _ = cv.Rodrigues(rotation)

    if rotation.shape != (3, 3):
        raise ValueError(
            f"Expected rotation matrix or rotation vector, got shape {rotation.shape}"
        )

    matrix = np.eye(4)
    matrix[:3, :3] = rotation
    matrix[:3, 3] = translation

    return Transformation.from_matrix(matrix.tolist())


def transformation_to_cv(
    transformation: Transformation,
) -> tuple[npt.NDArray[np.float64], npt.NDArray[np.float64]]:
    matrix = np.asarray(transformation.matrix, dtype=np.float64)

    return matrix[:3, :3], matrix[:3, 3]
