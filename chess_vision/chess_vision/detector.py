import typing

import cv2 as cv
import cv2.typing as cvt
import compas.geometry
import numpy as np

from chess_vision import CameraCalibration, ChArUcoBoard


@typing.final
class Detector:
    def __init__(self, board: ChArUcoBoard, camera_calibration: CameraCalibration):
        self.board = board
        self.camera_calibration = camera_calibration

        self._detector = cv.aruco.CharucoDetector(self.board.board)

    def detect_pose(self, frame: cvt.MatLike) -> compas.geometry.Transformation | None:

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

        return self.xform_from_cv(rvec, tvec)

    @staticmethod
    def xform_from_cv(
        rvec: cvt.MatLike, tvec: cvt.MatLike
    ) -> compas.geometry.Transformation:

        rot, _ = cv.Rodrigues(rvec)

        mat = np.eye(4)
        mat[:3, :3] = rot
        mat[:3, 3] = np.asarray(tvec).reshape(3)

        # tolist since pytest throws an error since compas upstream uses "if not
        # matrix"
        return compas.geometry.Transformation.from_matrix(mat.tolist())
