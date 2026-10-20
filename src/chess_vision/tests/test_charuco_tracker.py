from pathlib import Path

import compas.geometry
import cv2 as cv
import numpy as np
import pytest

from chess_vision.camera_calibration import CameraCalibration
from chess_vision.charuco_board import ChArUcoBoard
from chess_vision.charuco_tracker import ChArUcoTracker, ImageU8
from chess_vision.geometry import transformation_from_cv


def get_capture(video_path: Path):
    cap = cv.VideoCapture(str(video_path))
    assert cap.isOpened(), f"Failed to open video: {video_path}"

    return cap


@pytest.fixture
def sample_frame(calibration_video_path: Path) -> ImageU8:
    cap = get_capture(calibration_video_path)
    ok, frame = cap.read()

    assert ok

    return frame


@pytest.fixture
def camera_calibration(sample_frame: ImageU8) -> CameraCalibration:
    # sic
    h, w, _ = sample_frame.shape
    return CameraCalibration.create_dummy_intrinsics_from_image(w, h)


@pytest.fixture
def board():
    return ChArUcoBoard.from_board_parameters_dict("sample_calibration_video_board")


@pytest.fixture
def tracker(
    board: ChArUcoBoard, camera_calibration: CameraCalibration, tmp_path: Path
) -> ChArUcoTracker:
    return ChArUcoTracker(
        board, camera_calibration, debug_frame_dump_directory=tmp_path
    )


def test_charuco_markers_detector_with_sample_video(
    calibration_video_path: Path, tracker: ChArUcoTracker
):
    cap = get_capture(calibration_video_path)

    ok, _ = cap.read()

    assert ok

    frames_with_charuco = 0

    transformations: list[compas.geometry.Transformation] = []

    while cap.isOpened() and frames_with_charuco < 10:
        ret, frame = cap.read()
        if not ret:
            print("Can't recieve frame")
            break

        _marked_frame, detection = tracker.detect_pose(frame)

        if detection is not None:
            transformations.append(detection.transformation)

    cap.release()

    assert len(transformations) >= 10, "Less than 10 poses where calculated."
    assert isinstance(transformations[0], compas.geometry.Transformation)


def test_solve_pnp_matches_estimate_pose_charuco_board(
    tracker: ChArUcoTracker,
    sample_frame: ImageU8,
) -> None:
    """This tests that using SolvePnP on both cv 4.6 branch and +4.12 branch work, previously estimatePoseCharucoBoard was used on 4.6 branch"""
    (
        charuco_corners,
        charuco_ids,
        _marker_corners,
        _marker_ids,
    ) = tracker._detect_board(sample_frame)

    assert charuco_corners is not None
    assert charuco_ids is not None
    assert len(charuco_ids) >= 6

    # old path
    old_rvec = np.zeros((3, 1), dtype=np.float64)
    old_tvec = np.zeros((3, 1), dtype=np.float64)

    success, old_rvec, old_tvec = cv.aruco.estimatePoseCharucoBoard(
        charuco_corners,
        charuco_ids,
        tracker.board.board,
        tracker.camera_calibration.matrix,
        tracker.camera_calibration.dist_coeffs,
        old_rvec,
        old_tvec,
    )

    assert success

    old_transform = transformation_from_cv(
        old_rvec,
        old_tvec,
    )

    # new path
    object_points, image_points = tracker._match_image_points(
        charuco_corners,
        charuco_ids,
    )

    success, new_rvec, new_tvec = cv.solvePnP(
        object_points,
        image_points,
        tracker.camera_calibration.matrix,
        tracker.camera_calibration.dist_coeffs,
    )

    assert success

    new_transform = transformation_from_cv(
        new_rvec,
        new_tvec,
    )

    np.testing.assert_allclose(
        old_transform.matrix,
        new_transform.matrix,
        atol=1e-6,
    )
