import pathlib
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

        self._debug_save_image_with_drawn_markers_counter = 0

    def detect_pose(
        self,
        frame: cvt.MatLike,
        dump_debug_frame: bool = False,
        dump_debug_frame_directory: pathlib.Path | None = None,
    ) -> compas.geometry.Transformation | None:

        # detectBoard runs detectMarkers if charucoCorners and charucoIds are
        # not provided
        charucoCorners, charucoIds, markerCorners, markerIds = (
            self._detector.detectBoard(frame)
        )

        if dump_debug_frame:
            if dump_debug_frame_directory is None:
                raise RuntimeError(
                    "Can't dump_debug_frame without a dump_debug_frame_directory."
                )

            path = self.dump_debug_frame(
                frame.copy(),
                charucoCorners,
                charucoIds,
                markerCorners,
                markerIds,
                dump_debug_frame_directory,
            )
            print(f"Dumped frame: {path=}")

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

    def dump_debug_frame(
        self,
        frame: cvt.MatLike,
        charucoCorners: cvt.MatLike,
        charucoIds: cvt.MatLike,
        markerCorners: cvt.MatLike,
        markerIds: cvt.MatLike,
        save_directory: pathlib.Path,
    ) -> pathlib.Path:

        if frame.ndim == 2:
            frame = cv.cvtColor(frame, cv.COLOR_GRAY2BGR)

        if len(markerIds) > 0:
            _ = cv.aruco.drawDetectedMarkers(frame, markerCorners, markerIds)  # pyright: ignore[reportCallIssue, reportArgumentType]

        if charucoIds is not None and len(charucoIds) > 0:  # pyright: ignore[reportUnnecessaryComparison]
            _ = cv.aruco.drawDetectedCornersCharuco(frame, charucoCorners, charucoIds)

        path = pathlib.Path(
            save_directory
            / f"frame_{self._debug_save_image_with_drawn_markers_counter:03d}.png"
        )

        self._debug_save_image_with_drawn_markers_counter += 1

        _ = cv.imwrite(str(path), frame)

        return path

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
