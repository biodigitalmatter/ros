import os

import compas
import cv2 as cv

from chess_vision import CameraCalibration, ChArUcoBoard, Detector


def get_capture(video_path: os.PathLike[str]):
    cap = cv.VideoCapture(str(video_path))
    assert cap.isOpened(), f"Failed to open video: {video_path}"

    return cap


def test_charuco_markers_detector_with_sample_video(calibration_video_path, tmp_path):
    cap = get_capture(calibration_video_path)

    ok, frame = cap.read()

    assert ok

    # sic
    h, w, _ = frame.shape

    camera_calibration = CameraCalibration.create_dummy_intrinsics_from_image(w, h)
    board = ChArUcoBoard.from_board_parameters_dict("sample_calibration_video_board")
    detector = Detector(board, camera_calibration, debug_frame_dump_directory=tmp_path)

    frames_with_charuco = 0

    xforms: list[compas.geometry.Transformation] = []

    while cap.isOpened() and frames_with_charuco < 10:
        ret, frame = cap.read()
        if not ret:
            print("Can't recieve frame")
            break

        _marked_frame, _markerIds, xform = detector.detect_pose(frame)

        if xform is not None:
            xforms.append(xform)

    cap.release()

    assert len(xforms) >= 10, "Less than 10 poses where calculated."
    assert isinstance(xforms[0], compas.geometry.Transformation)
