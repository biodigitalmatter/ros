from pathlib import Path

import pytest


@pytest.fixture
def fixture_dir():
    return Path(__file__).parent / "fixtures"


@pytest.fixture
def calibration_video_path(fixture_dir):
    path = fixture_dir / "sample_calibration_video.mp4"
    assert path.exists()
    return path
