from pathlib import Path

from chess_vision_ros.eye_in_hand import (
    BagReader,
    EyeInHandConfig,
    calibrate_eye_in_hand_from_bag,
    eye_in_hand_samples_from_bag,
)

HERE = Path(__file__).parent
REPO_ROOT = HERE.parents[2]
ROSBAGS_DIR = REPO_ROOT / "tmp" / "rosbags" / "hand_eye_bags"
BAG_PATH = ROSBAGS_DIR / "202610011758"

bag = BagReader(BAG_PATH)
config = EyeInHandConfig(
    base_frame="map",
    gripper_frame="tool0",
    camera_frame="extruder_d405_color_optical_frame",
    target_frame="charuco_board",
)
print(bag.metadata)
samples = eye_in_hand_samples_from_bag(bag, config)

print(f"Found {len(samples)} samples")

for sample in samples[:5]:
    print("gripper2base:")
    print(sample.gripper2base)

    print("target2cam:")
    print(sample.target2cam)

print("Sampling every 500")
print()

for sample in samples[::500]:
    print("gripper2base:")
    print(sample.gripper2base)

    print("target2cam:")
    print(sample.target2cam)

result = calibrate_eye_in_hand_from_bag(bag, config)

print(result.cam2gripper)
