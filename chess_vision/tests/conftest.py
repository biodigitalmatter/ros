from pathlib import Path

import pytest


@pytest.fixture
def fixture_dir():
    return Path(__file__).parent / "fixtures"


@pytest.fixture
def calibration_video_path(fixture_dir):
    path = fixture_dir / "sample_calibration_video" / "sample_calibration_video.mp4"
    assert path.exists()
    return path


@pytest.fixture
def rosbag_path(fixture_dir):
    path_ = fixture_dir / "sample_calibration_video" / "rosbag"

    datapath = path_ / "rosbag_0.mcap"

    if not datapath.exists():
        raise RuntimeError("rosbag not found, check README.md on how to create")

    return path_


@pytest.fixture
def calibration_yaml_path(fixture_dir):
    return fixture_dir / "sample_calibration.yaml"
