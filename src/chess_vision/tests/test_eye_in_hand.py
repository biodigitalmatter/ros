import math

import numpy as np
import pytest
from compas.geometry import Rotation, Transformation, Translation, Vector

from chess_vision.eye_in_hand import EyeInHandSample, calibrate_eye_in_hand


@pytest.mark.parametrize("sample_count", [0, 1, 2])
def test_solver_rejects_too_few_samples(sample_count) -> None:
    sample = EyeInHandSample(
        Transformation(),
        Transformation(),
    )

    with pytest.raises(ValueError, match="At least 3 samples are required"):
        calibrate_eye_in_hand([sample] * sample_count)


def test_sample_compas_json_roundtrip() -> None:
    sample = EyeInHandSample(
        gripper2base=Translation.from_vector([1.0, 2.0, 3.0]),
        target2cam=Rotation.from_axis_and_angle(Vector.Zaxis(), math.radians(20)),
    )

    loaded = EyeInHandSample.from_jsonstring(sample.to_jsonstring())

    assert np.allclose(loaded.gripper2base.matrix, sample.gripper2base.matrix)
    assert np.allclose(loaded.target2cam.matrix, sample.target2cam.matrix)
