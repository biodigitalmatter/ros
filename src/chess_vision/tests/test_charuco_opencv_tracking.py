import cv2
from cv2 import aruco

from chess_vision import ChArUcoBoard


def test_charuco_markers_detect_in_sample_video(calibration_video_path):
    cap = cv2.VideoCapture(str(calibration_video_path))
    assert cap.isOpened(), f"Failed to open video: {calibration_video_path}"

    # read first frame to test
    ok, frame = cap.read()
    assert ok and frame is not None, (
        f"Could not read first frame from: {calibration_video_path}"
    )

    board = ChArUcoBoard.from_board_parameters_dict("sample_calibration_video_board")
    dictionary = board.dictionary

    best_charuco_corners = 0
    frames_with_charuco = 0

    frame_idx = 0
    try:
        while frame_idx < 120:
            ok, frame = cap.read()
            if not ok:
                break

            if frame_idx % 5 != 0:
                frame_idx += 1
                continue

            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            corners, ids, _ = aruco.detectMarkers(gray, dictionary)
            if ids is None or len(ids) == 0:
                frame_idx += 1
                continue

            retval, _, _ = aruco.interpolateCornersCharuco(
                corners, ids, gray, board.board
            )
            if retval > 0:
                frames_with_charuco += 1
                best_charuco_corners = max(best_charuco_corners, int(retval))

            frame_idx += 1
    finally:
        cap.release()

    assert frames_with_charuco > 0, "No ChArUco corners detected in sample video."
    assert best_charuco_corners >= 10, (
        f"Too few ChArUco corners detected (best={best_charuco_corners})."
    )
