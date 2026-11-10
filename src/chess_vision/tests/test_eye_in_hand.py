import math

import numpy as np
import pytest
from compas.geometry import Rotation, Transformation, Translation, Vector

from chess_vision.eye_in_hand import (
    EyeInHandSample,
    HandEyeMethod,
    calibrate_eye_in_hand,
)


@pytest.mark.parametrize("sample_count", [0, 1, 2])
def test_solver_rejects_too_few_samples(sample_count) -> None:
    sample = EyeInHandSample(
        Transformation(),
        Transformation(),
    )

    with pytest.raises(ValueError, match="At least 3 samples are required"):
        calibrate_eye_in_hand([sample] * sample_count)


def test_solver_recovers_known_camera_to_gripper_transform() -> None:
    camera2gripper = Translation.from_vector([0.08, -0.03, 0.12]) * (
        Rotation.from_axis_and_angle(Vector.Xaxis(), math.radians(12))
        * Rotation.from_axis_and_angle(Vector.Zaxis(), math.radians(-18))
    )
    target2base = Translation.from_vector(
        [0.7, 0.1, 0.3]
    ) * Rotation.from_axis_and_angle(Vector.Yaxis(), math.radians(25))

    pose_parameters = [
        ([0.30, -0.20, 0.40], Vector.Xaxis(), -35),
        ([0.38, -0.10, 0.32], Vector.Yaxis(), 28),
        ([0.42, 0.02, 0.36], Vector.Zaxis(), 42),
        ([0.32, 0.12, 0.44], Vector.Xaxis(), 31),
        ([0.25, 0.04, 0.50], Vector.Yaxis(), -38),
        ([0.45, -0.16, 0.48], Vector.Zaxis(), -29),
    ]
    samples = []
    for translation, axis, angle_degrees in pose_parameters:
        gripper2base = Translation.from_vector(
            translation
        ) * Rotation.from_axis_and_angle(axis, math.radians(angle_degrees))
        camera2base = gripper2base * camera2gripper
        samples.append(
            EyeInHandSample(
                gripper2base=gripper2base,
                target2cam=camera2base.inverse() * target2base,
            )
        )

    result = calibrate_eye_in_hand(samples, method=HandEyeMethod.TSAI)

    assert np.allclose(result.cam2gripper.matrix, camera2gripper.matrix, atol=1e-7)


def test_sample_compas_json_roundtrip() -> None:
    sample = EyeInHandSample(
        gripper2base=Translation.from_vector([1.0, 2.0, 3.0]),
        target2cam=Rotation.from_axis_and_angle(Vector.Zaxis(), math.radians(20)),
    )

    loaded = EyeInHandSample.from_jsonstring(sample.to_jsonstring())

    assert np.allclose(loaded.gripper2base.matrix, sample.gripper2base.matrix)
    assert np.allclose(loaded.target2cam.matrix, sample.target2cam.matrix)
