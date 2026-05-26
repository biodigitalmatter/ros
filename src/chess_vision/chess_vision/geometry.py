import cv2 as cv
import numpy as np
import numpy.typing as npt
from compas.geometry import Frame, Transformation


def xform_from_cv(
    R: npt.NDArray[np.float64], t: npt.NDArray[np.float64]
) -> Transformation:
    R = np.asarray(R, dtype=np.float64)
    t = np.asarray(t, dtype=np.float64).reshape(3)

    if R.shape in ((3,), (3, 1), (1, 3)):
        R, _ = cv.Rodrigues(R)

    if R.shape != (3, 3):
        raise ValueError(
            f"Expected rotation matrix or Rodrigues vector, got shape {R.shape}"
        )

    return Transformation.from_frame(
        Frame(
            point=t.tolist(),
            xaxis=R[:, 0].tolist(),
            yaxis=R[:, 1].tolist(),
        )
    )
