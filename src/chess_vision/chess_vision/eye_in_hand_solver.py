import typing

import compas.data
import cv2 as cv
import numpy as np
import numpy.typing as npt
from compas.geometry import Transformation

from chess_vision.geometry import camera_transform_from_cv


@typing.final
class Sample(compas.data.Data):
    DATASCHEMA = {
        "type": "object",
        "properties": {
            "gripper2base": Transformation.DATASCHEMA,
            "target2cam": Transformation.DATASCHEMA,
        },
        "required": ["gripper2base", "target2cam"],
    }

    @property
    def __data__(self):
        return {
            "gripper2base": self.gripper2base.__data__,
            "target2cam": self.target2cam.__data__,
        }

    def __init__(
        self,
        gripper2base: Transformation,
        target2cam: Transformation,
        name: str | None = None,
    ):
        super(Sample, self).__init__(name=name)

        self.gripper2base = gripper2base
        self.target2cam = target2cam

    def as_cv_input(
        self,
    ) -> tuple[
        npt.NDArray[np.float64],
        npt.NDArray[np.float64],
        npt.NDArray[np.float64],
        npt.NDArray[np.float64],
    ]:
        return (
            self._rotation_matrix(self.gripper2base),
            self._translation_vector(self.gripper2base),
            self._rotation_matrix(self.target2cam),
            self._translation_vector(self.target2cam),
        )

    @staticmethod
    def _rotation_matrix(T: Transformation) -> npt.NDArray[np.float64]:
        return np.asarray(T.matrix, dtype=np.float64)[:3, :3]

    @staticmethod
    def _translation_vector(T: Transformation) -> npt.NDArray[np.float64]:
        return np.asarray(T.matrix, dtype=np.float64)[:3, 3]


@typing.final
class EyeInHandSolver:
    def __init__(self, method: int = cv.CALIB_HAND_EYE_TSAI):
        self.samples: list[Sample] = []
        self.method: int = method

    def solve(self) -> Transformation:
        """Return the camera-to-gripper transformation."""
        if len(self.samples) < 3:
            raise RuntimeError(f"Not enough samples, got {len(self.samples)}")

        R_gripper2base, t_gripper2base, R_target2cam, t_target2cam = map(
            list,
            zip(*(sample.as_cv_input() for sample in self.samples)),
        )

        R_cam2gripper, t_cam2gripper = cv.calibrateHandEye(
            R_gripper2base=R_gripper2base,
            t_gripper2base=t_gripper2base,
            R_target2cam=R_target2cam,
            t_target2cam=t_target2cam,
            method=self.method,
        )

        camera2gripper = camera_transform_from_cv(
            R_cam2gripper,
            t_cam2gripper,
        )

        return camera2gripper
