from datetime import datetime, timezone

import numpy as np
import pytest
from click.testing import CliRunner
from compas.geometry import Rotation, Transformation, Translation

from chess_vision.eye_in_hand import EyeInHandResult, HandEyeMethod
from chess_vision_ros.calibrate_eye_in_hand import main
from chess_vision_ros.eye_in_hand import (
    EyeInHandCalibration,
    EyeInHandConfig,
    EyeInHandQuality,
)


def test_calibration_compas_json_roundtrip() -> None:
    transformation = Translation.from_vector(
        [0.1, 0.2, 0.3]
    ) * Rotation.from_quaternion([0.5, 0.5, 0.5, 0.5])
    result = EyeInHandResult(
        cam2gripper=transformation,
        method=HandEyeMethod.PARK,
    )
    quality = EyeInHandQuality(
        target_center_m=(0.4, 0.5, 0.6),
        target_std_mm=(1.0, 2.0, 3.0),
        rms_mm=4.0,
        median_mm=3.0,
        p95_mm=6.0,
        maximum_mm=7.0,
    )
    generated_at = datetime(2026, 11, 10, 12, 0, tzinfo=timezone.utc)

    calibration = EyeInHandCalibration(
        config=EyeInHandConfig(method=HandEyeMethod.PARK),
        sample_count=12,
        result=result,
        quality=quality,
        generated_at=generated_at,
    )
    loaded = EyeInHandCalibration.from_jsonstring(calibration.to_jsonstring())

    assert loaded.config == calibration.config
    assert loaded.sample_count == 12
    assert loaded.result.method is HandEyeMethod.PARK
    assert np.allclose(loaded.result.cam2gripper.matrix, transformation.matrix)
    assert loaded.quality == quality
    assert loaded.generated_at == generated_at


def test_cli_rejects_unknown_method(tmp_path) -> None:
    result = CliRunner().invoke(
        main,
        [str(tmp_path), "--output", "result.json", "--method", "unknown"],
    )

    assert result.exit_code == 2
    assert "Invalid value for '--method'" in result.output


def test_quality_rejects_empty_samples() -> None:
    from chess_vision_ros.eye_in_hand import eye_in_hand_quality

    result = EyeInHandResult(Transformation(), HandEyeMethod.TSAI)

    with pytest.raises(ValueError, match="At least one sample"):
        eye_in_hand_quality([], result)
