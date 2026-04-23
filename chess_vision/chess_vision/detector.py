import typing

import numpy as np
import cv2 as cv
import cv2.typing as cvt
from scipy.spatial.transform import Rotation

from chess_vision import CameraCalibration, ChArUcoBoard


@typing.final
class Detector:
    def __init__(self, board: ChArUcoBoard, camera_calibration: CameraCalibration):
        self.board = board
        self.camera_calibration = camera_calibration

        self._detector = cv.aruco.CharucoDetector(self.board.board)

    def detect_pose(
        self, frame: cvt.MatLike
    ) -> tuple[float, float, float, float, float, float, float] | None:

        # detectBoard runs detectMarkers if charucoCorners and charucoIds are
        # not provided
        charucoCorners, charucoIds, markerCorners, markerIds = (
            self._detector.detectBoard(frame)
        )

        if len(markerIds) < 1:
            print("Didn't detect any ArUco markers")
            return None

        if charucoIds is None or len(charucoIds) < 4:  # pyright: ignore[reportUnnecessaryComparison]
            print("Didn't detect enough ChArUco corners")
            return None

        obj_points, img_points = self.board.board.matchImagePoints(  # pyright: ignore[reportCallIssue]
            charucoCorners,  # pyright: ignore[reportArgumentType]
            charucoIds,
        )

        success, rvec, tvec = cv.solvePnP(
            obj_points,
            img_points,
            self.camera_calibration.matrix,
            self.camera_calibration.dist_coeffs,
        )

        if not success:
            return

        return self.pose_from_cv(rvec, tvec)

    @staticmethod
    def pose_from_cv(rvec: np.ndarray, tvec: np.ndarray):
        x = tvec[0][0]
        y = tvec[1][0]
        z = tvec[2][0]

        rot_matrix, _ = cv.Rodrigues(rvec)
        qx, qy, qz, qw = Rotation.from_matrix(rot_matrix).as_quat()

        return x, y, z, qx, qy, qz, qw
