import dataclasses
import enum
import typing
from collections.abc import Sequence

import cv2 as cv
from compas.data import Data
from compas.geometry import Transformation

from chess_vision.geometry import (
    transformation_from_cv,
    transformation_to_cv,
)


@dataclasses.dataclass
class EyeInHandSample(Data):
    gripper2base: Transformation
    target2cam: Transformation

    def __post_init__(self) -> None:
        super().__init__()

    @property
    def __data__(self) -> dict[str, Transformation]:
        return {
            "gripper2base": self.gripper2base,
            "target2cam": self.target2cam,
        }


class HandEyeMethod(enum.IntEnum):
    TSAI = cv.CALIB_HAND_EYE_TSAI
    PARK = cv.CALIB_HAND_EYE_PARK
    HORAUD = cv.CALIB_HAND_EYE_HORAUD
    ANDREFF = cv.CALIB_HAND_EYE_ANDREFF
    DANIILIDIS = cv.CALIB_HAND_EYE_DANIILIDIS


@dataclasses.dataclass
class EyeInHandResult(Data):
    cam2gripper: Transformation
    method: HandEyeMethod

    def __post_init__(self) -> None:
        super().__init__()

    @property
    def __data__(self) -> dict[str, Transformation | str]:
        return {
            "cam2gripper": self.cam2gripper,
            "method": self.method.name,
        }

    @classmethod
    def __from_data__(cls, data: dict) -> typing.Self:
        return cls(
            cam2gripper=data["cam2gripper"],
            method=HandEyeMethod[data["method"]],
        )


def calibrate_eye_in_hand(
    samples: Sequence[EyeInHandSample], method: HandEyeMethod = HandEyeMethod.TSAI
) -> EyeInHandResult:
    """Return the camera-to-gripper transformation."""
    if len(samples) < 3:
        raise ValueError(f"At least 3 samples are required, got {len(samples)}")

    R_gripper2base, t_gripper2base = zip(
        *(transformation_to_cv(s.gripper2base) for s in samples)
    )

    R_target2cam, t_target2cam = zip(
        *(transformation_to_cv(s.target2cam) for s in samples)
    )

    R_cam2gripper, t_cam2gripper = cv.calibrateHandEye(
        R_gripper2base,
        t_gripper2base,
        R_target2cam,
        t_target2cam,
        method=method,
    )

    return EyeInHandResult(
        cam2gripper=transformation_from_cv(R_cam2gripper, t_cam2gripper),
        method=method,
    )
