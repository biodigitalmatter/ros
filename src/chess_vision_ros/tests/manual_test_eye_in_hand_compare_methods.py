from pathlib import Path

import numpy as np

from chess_vision.eye_in_hand import HandEyeMethod, calibrate_eye_in_hand
from chess_vision_ros.bag import BagReader
from chess_vision_ros.eye_in_hand import (
    EyeInHandConfig,
    eye_in_hand_samples_from_bag,
)

HERE = Path(__file__).parent
REPO_ROOT = HERE.parents[2]
ROSBAGS_DIR = REPO_ROOT / "tmp" / "rosbags" / "hand_eye_bags"
BAG_PATH = ROSBAGS_DIR / "202610011758"


def main() -> None:
    bag = BagReader(Path(BAG_PATH))

    config = EyeInHandConfig(
        base_frame="map",
        gripper_frame="tool0",
        camera_frame="extruder_d405_color_optical_frame",
        target_frame="charuco_board",
    )

    samples = eye_in_hand_samples_from_bag(bag, config)

    print(f"Using {len(samples)} samples")
    print()

    for method in HandEyeMethod:
        result = calibrate_eye_in_hand(
            samples,
            method=method,
        )

        # target pose in base frame
        target2base = [
            sample.gripper2base * result.cam2gripper * sample.target2cam
            for sample in samples
        ]

        positions = np.asarray(
            [T.translation_vector for T in target2base],
            dtype=np.float64,
        )

        center = positions.mean(axis=0)
        std = positions.std(axis=0)

        errors = np.linalg.norm(
            positions - center,
            axis=1,
        )

        rms = np.sqrt(np.mean(errors**2))
        median = np.median(errors)
        p95 = np.percentile(errors, 95)
        maximum = errors.max()

        print(method.name)

        print(f"  target xyz: {center[0]:.4f}, {center[1]:.4f}, {center[2]:.4f} m")

        print(
            "  std xyz:    "
            f"{std[0] * 1000:.2f}, "
            f"{std[1] * 1000:.2f}, "
            f"{std[2] * 1000:.2f} mm"
        )

        print(f"  RMS:        {rms * 1000:.2f} mm")
        print(f"  median:     {median * 1000:.2f} mm")
        print(f"  p95:        {p95 * 1000:.2f} mm")
        print(f"  max:        {maximum * 1000:.2f} mm")

        print("  cam2gripper:")
        print(result.cam2gripper)
        print()


if __name__ == "__main__":
    main()
