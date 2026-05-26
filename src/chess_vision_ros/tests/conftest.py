from pathlib import Path

import pytest


@pytest.fixture
def fixture_dir() -> Path:
    return Path(__file__).parent / "fixtures"


@pytest.fixture
def calibration_video_path(fixture_dir: Path):
    path = fixture_dir / "sample_calibration_video.mp4"
    assert path.exists()
    return path


@pytest.fixture
def rosbag_path(fixture_dir: Path) -> Path:
    path_ = fixture_dir / "rosbag"

    datapath = path_ / "rosbag_0.mcap"

    if not datapath.exists():
        raise RuntimeError("rosbag not found, check README.md on how to create")

    return path_


@pytest.fixture
def sample_camera_info_path(fixture_dir: Path) -> Path:
    return fixture_dir / "sample_camera_info.json"
