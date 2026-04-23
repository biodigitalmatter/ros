import cv2

from chess_vision import boards


def test_charuco_markers_detect_in_sample_video(calibration_video_path):
    cap = cv2.VideoCapture(str(calibration_video_path))
    assert cap.isOpened(), f"Failed to open video: {calibration_video_path}"

    board = boards.ChessBoard.from_board_parameters_dict(
        "sample_calibration_video_board"
    )

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
            corners, ids, _ = cv2.aruco.detectMarkers(gray, board.dictionary)
            if ids is None or len(ids) == 0:
                frame_idx += 1
                continue

            retval, _, _ = cv2.aruco.interpolateCornersCharuco(
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
