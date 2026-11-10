import math
from dataclasses import dataclass
from datetime import datetime, timezone

import numpy as np
from compas.data import Data
from compas.geometry import Transformation
from tf2_ros import ExtrapolationException  # ty:ignore[unresolved-import]

from chess_vision.eye_in_hand import (
    EyeInHandResult,
    EyeInHandSample,
    HandEyeMethod,
    calibrate_eye_in_hand,
)
from chess_vision_ros.bag import BagReader
from chess_vision_ros.tf import BagTransformBuffer


@dataclass
class EyeInHandConfig(Data):
    base_frame: str = "base_link"
    gripper_frame: str = "tool0"
    camera_frame: str = "camera_color_optical_frame"
    target_frame: str = "charuco"
    method: HandEyeMethod = HandEyeMethod.TSAI

    min_translation: float = 0.02
    min_rotation: float = math.radians(5)

    def __post_init__(self) -> None:
        super().__init__()

    @property
    def __data__(self) -> dict[str, str | float]:
        return {
            "base_frame": self.base_frame,
            "gripper_frame": self.gripper_frame,
            "camera_frame": self.camera_frame,
            "target_frame": self.target_frame,
            "method": self.method.name,
            "min_translation": self.min_translation,
            "min_rotation": self.min_rotation,
        }

    @classmethod
    def __from_data__(cls, data: dict[str, str | float]) -> "EyeInHandConfig":
        return cls(
            base_frame=data["base_frame"],
            gripper_frame=data["gripper_frame"],
            camera_frame=data["camera_frame"],
            target_frame=data["target_frame"],
            method=HandEyeMethod[data["method"]],
            min_translation=data["min_translation"],
            min_rotation=data["min_rotation"],
        )


@dataclass
class EyeInHandQuality(Data):
    target_center_m: tuple[float, float, float]
    target_std_mm: tuple[float, float, float]
    rms_mm: float
    median_mm: float
    p95_mm: float
    maximum_mm: float

    def __post_init__(self) -> None:
        super().__init__()

    @property
    def __data__(self) -> dict:
        return {
            "target_center_m": self.target_center_m,
            "target_std_mm": self.target_std_mm,
            "rms_mm": self.rms_mm,
            "median_mm": self.median_mm,
            "p95_mm": self.p95_mm,
            "maximum_mm": self.maximum_mm,
        }

    @classmethod
    def __from_data__(cls, data: dict) -> "EyeInHandQuality":
        return cls(
            target_center_m=tuple(data["target_center_m"]),
            target_std_mm=tuple(data["target_std_mm"]),
            rms_mm=data["rms_mm"],
            median_mm=data["median_mm"],
            p95_mm=data["p95_mm"],
            maximum_mm=data["maximum_mm"],
        )


class EyeInHandCalibration(Data):
    def __init__(
        self,
        config: EyeInHandConfig,
        sample_count: int,
        result: EyeInHandResult,
        quality: EyeInHandQuality,
        generated_at: datetime | None = None,
    ):
        super().__init__()
        if config.method != result.method:
            raise ValueError(
                f"Config method {config.method.name} does not match "
                f"result method {result.method.name}"
            )
        self.config = config
        self.sample_count = sample_count
        self.result = result
        self.quality = quality
        self.generated_at = generated_at or datetime.now(timezone.utc)

    @property
    def __data__(self) -> dict:
        return {
            "version": 1,
            "generated_at": self.generated_at.isoformat(),
            "config": self.config,
            "sample_count": self.sample_count,
            "result": self.result,
            "quality": self.quality,
        }

    @classmethod
    def __from_data__(cls, data: dict) -> "EyeInHandCalibration":
        return cls(
            config=data["config"],
            sample_count=data["sample_count"],
            result=data["result"],
            quality=data["quality"],
            generated_at=datetime.fromisoformat(data["generated_at"]),
        )


def _poses_differ_p(
    previous: Transformation,
    current: Transformation,
    min_translation: float,
    min_rotation: float,
) -> bool:
    delta = previous.inverse() * current

    translation = delta.translation_vector.length
    _, angle = delta.rotation.axis_and_angle

    return translation >= min_translation or abs(angle) >= min_rotation


def eye_in_hand_samples_from_bag(
    bag: BagReader,
    config: EyeInHandConfig,
) -> list[EyeInHandSample]:
    tf = BagTransformBuffer(bag)

    samples: list[EyeInHandSample] = []

    for target in tf.transforms(
        config.camera_frame,
        config.target_frame,
    ):
        try:
            gripper2base = tf.lookup_transform(
                config.base_frame,
                config.gripper_frame,
                target.timestamp_ns,
            )
        except ExtrapolationException:
            continue

        sample = EyeInHandSample(
            gripper2base=gripper2base, target2cam=target.transformation
        )

        if len(samples) > 0 and not _poses_differ_p(
            samples[-1].gripper2base,
            sample.gripper2base,
            config.min_translation,
            config.min_rotation,
        ):
            continue

        samples.append(sample)

    return samples


def calibrate_eye_in_hand_from_bag(
    bag: BagReader, config: EyeInHandConfig
) -> EyeInHandResult:
    samples = eye_in_hand_samples_from_bag(bag, config)

    return calibrate_eye_in_hand(samples, method=config.method)


def eye_in_hand_quality(
    samples: list[EyeInHandSample], result: EyeInHandResult
) -> EyeInHandQuality:
    if len(samples) == 0:
        raise ValueError(
            "At least one sample is required to evaluate calibration quality"
        )

    target2base = [
        sample.gripper2base * result.cam2gripper * sample.target2cam
        for sample in samples
    ]
    positions = np.asarray(
        [transformation.translation_vector for transformation in target2base],
        dtype=np.float64,
    )

    center = positions.mean(axis=0)
    std = positions.std(axis=0)
    errors = np.linalg.norm(positions - center, axis=1)

    return EyeInHandQuality(
        target_center_m=tuple(float(value) for value in center),
        target_std_mm=tuple(float(value * 1000) for value in std),
        rms_mm=float(np.sqrt(np.mean(errors**2)) * 1000),
        median_mm=float(np.median(errors) * 1000),
        p95_mm=float(np.percentile(errors, 95) * 1000),
        maximum_mm=float(errors.max() * 1000),
    )
