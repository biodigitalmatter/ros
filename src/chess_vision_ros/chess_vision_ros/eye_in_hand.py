from dataclasses import dataclass

from tf2_ros import ExtrapolationException

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

        samples.append(
            EyeInHandSample(gripper2base=gripper2base, target2cam=target.transformation)
        )

    return samples


def calibrate_eye_in_hand_from_bag(
    bag: BagReader, config: EyeInHandConfig
) -> EyeInHandResult:
    samples = eye_in_hand_samples_from_bag(bag, config)

    return calibrate_eye_in_hand(samples, method=config.method)
