import pytest
from compas.geometry import Transformation

from chess_vision.eye_in_hand import EyeInHandSample, calibrate_eye_in_hand


@pytest.mark.parametrize("sample_count", [0, 1, 2])
def test_solver_rejects_too_few_samples(sample_count) -> None:
    sample = EyeInHandSample(
        Transformation(),
        Transformation(),
    )

    with pytest.raises(ValueError, match="At least 3 samples are required"):
        calibrate_eye_in_hand([sample] * sample_count)
