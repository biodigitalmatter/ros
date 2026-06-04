import pathlib
import typing

import compas.geometry
import cv2 as cv
import numpy as np
import numpy.typing as npt

from chess_vision import CameraCalibration, ChArUcoBoard
from chess_vision.geometry import xform_from_cv

ImageU8 = npt.NDArray[np.uint8]
MarkerIDs = npt.NDArray[np.uint8]
CornerCoordinates = npt.NDArray[np.float64]


@typing.final
class Detector:
    def __init__(
        self,
        board: ChArUcoBoard,
        camera_calibration: CameraCalibration,
        debug_frame_dump_directory: pathlib.Path | None = None,
    ):
        self.board = board
        self.camera_calibration = camera_calibration

        self.debug_frame_dump_directory = debug_frame_dump_directory

        if self.debug_frame_dump_directory is not None:
            if not self.debug_frame_dump_directory.exists():
                raise RuntimeError(f"{self.debug_frame_dump_directory=} doesn't exist.")

        self._detector = cv.aruco.CharucoDetector(self.board.board)

        self._debug_save_image_with_drawn_markers_counter = 0

    def detect_pose(
        self,
        frame: ImageU8,
    ) -> tuple[
        ImageU8,
        MarkerIDs | None,
        compas.geometry.Transformation | None,
    ]:
        # detectBoard runs detectMarkers if charucoCorners and charucoIds are
        # not provided
        charucoCorners, charucoIds, markerCorners, markerIds = (
            self._detector.detectBoard(frame)
        )

        marked_frame = self.draw_debug_frame(
            frame.copy(),
            charucoCorners,  # pyright: ignore[reportArgumentType]
            charucoIds,  # pyright: ignore[reportArgumentType]
            markerCorners,  # pyright: ignore[reportArgumentType]
            markerIds,  # pyright: ignore[reportArgumentType]
        )

        if self.debug_frame_dump_directory is not None:
            path = self.dump_debug_frame(
                marked_frame,
            )
            print(f"Dumped frame: {path=}")

        if markerIds is None or len(markerIds) < 1:
            print("Didn't detect any ArUco markers")
            return marked_frame, None, None

        if charucoIds is None or len(charucoIds) < 6:  # pyright: ignore[reportUnnecessaryComparison]
            print("Didn't detect enough ChArUco corners")
            return marked_frame, markerIds, None

        obj_points, img_points = self.board.board.matchImagePoints(  # pyright: ignore[reportCallIssue, reportUnknownVariableType]
            charucoCorners,
            charucoIds,
        )

        success, rvec, tvec = cv.solvePnP(
            obj_points,
            img_points,
            self.camera_calibration.matrix,
            self.camera_calibration.dist_coeffs,
        )

        if not success:
            return marked_frame, markerIds, None

        xform = xform_from_cv(rvec, tvec)

        return marked_frame, markerIds, xform

    def draw_debug_frame(
        self,
        frame: ImageU8,
        charucoCorners: CornerCoordinates | None,
        charucoIds: MarkerIDs | None,
        markerCorners: CornerCoordinates | None,
        markerIds: MarkerIDs | None,
    ) -> ImageU8:
        if frame.ndim == 2:
            frame = cv.cvtColor(frame, cv.COLOR_GRAY2BGR)  # pyright: ignore[reportAssignmentType]

        # if markerIds is not None and len(markerIds) > 0:
        #     _ = cv.aruco.drawDetectedMarkers(
        #         frame,
        #         markerCorners,
        #         markerIds,
        #     )

        if charucoIds is not None and len(charucoIds) > 0:
            _ = cv.aruco.drawDetectedCornersCharuco(
                frame,
                charucoCorners,
                charucoIds,
            )

        return frame

    def dump_debug_frame(
        self,
        frame: ImageU8,
    ):

        path = pathlib.Path(
            self.debug_frame_dump_directory
            / f"frame_{self._debug_save_image_with_drawn_markers_counter:03d}.png"
        )

        self._debug_save_image_with_drawn_markers_counter += 1

        _ = cv.imwrite(str(path), frame)

        return path
