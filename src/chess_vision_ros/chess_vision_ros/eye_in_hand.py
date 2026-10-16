import math
from dataclasses import dataclass

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


@dataclass(frozen=True)
class EyeInHandConfig:
    base_frame: str = "base_link"
    gripper_frame: str = "tool0"
    camera_frame: str = "camera_color_optical_frame"
    target_frame: str = "charuco"
    method: HandEyeMethod = HandEyeMethod.TSAI

    min_translation: float = 0.02
    min_rotation: float = math.radians(5)


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
