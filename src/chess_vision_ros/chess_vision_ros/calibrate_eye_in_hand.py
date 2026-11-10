import argparse
import math
from pathlib import Path

from chess_vision.eye_in_hand import HandEyeMethod, calibrate_eye_in_hand
from chess_vision_ros.bag import BagReader
from chess_vision_ros.eye_in_hand import (
    EyeInHandCalibration,
    EyeInHandConfig,
    eye_in_hand_quality,
    eye_in_hand_samples_from_bag,
)


def create_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Calibrate an eye-in-hand camera from a ROS bag."
    )
    parser.add_argument("bag", type=Path, help="ROS bag directory")
    parser.add_argument(
        "--output", required=True, type=Path, help="Output COMPAS JSON path"
    )
    parser.add_argument("--base-frame", default="map")
    parser.add_argument("--gripper-frame", default="tool0")
    parser.add_argument("--camera-frame", default="extruder_d405_color_optical_frame")
    parser.add_argument("--target-frame", default="charuco_board")
    parser.add_argument(
        "--method",
        choices=[method.name.lower() for method in HandEyeMethod],
        default=HandEyeMethod.TSAI.name.lower(),
    )
    parser.add_argument("--min-translation", type=float, default=0.02)
    parser.add_argument("--min-rotation-deg", type=float, default=5.0)
    return parser


def main(args: list[str] | None = None) -> None:
    parser = create_parser()
    parsed = parser.parse_args(args)

    if not parsed.bag.is_dir():
        parser.error(f"Bag directory does not exist: {parsed.bag}")
    if parsed.output.exists():
        parser.error(f"Output already exists: {parsed.output}")
    if not parsed.output.parent.is_dir():
        parser.error(f"Output directory does not exist: {parsed.output.parent}")
    if parsed.min_translation < 0:
        parser.error("--min-translation must be non-negative")
    if parsed.min_rotation_deg < 0:
        parser.error("--min-rotation-deg must be non-negative")

    config = EyeInHandConfig(
        base_frame=parsed.base_frame,
        gripper_frame=parsed.gripper_frame,
        camera_frame=parsed.camera_frame,
        target_frame=parsed.target_frame,
        method=HandEyeMethod[parsed.method.upper()],
        min_translation=parsed.min_translation,
        min_rotation=math.radians(parsed.min_rotation_deg),
    )

    try:
        samples = eye_in_hand_samples_from_bag(BagReader(parsed.bag), config)
        result = calibrate_eye_in_hand(samples, method=config.method)
        quality = eye_in_hand_quality(samples, result)
        calibration = EyeInHandCalibration(
            config=config,
            sample_count=len(samples),
            result=result,
            quality=quality,
        )
        calibration.to_json(str(parsed.output), pretty=True, minimal=True)
    except (OSError, RuntimeError, ValueError) as error:
        parser.error(str(error))

    print(f"Used {len(samples)} samples")
    print(f"Method: {result.method.name}")
    print(f"Target consistency RMS: {quality.rms_mm:.2f} mm")
    print(f"Target consistency p95: {quality.p95_mm:.2f} mm")
    print(f"Wrote calibration: {parsed.output}")


if __name__ == "__main__":
    main()
