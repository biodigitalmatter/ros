import pathlib
import typing
from dataclasses import dataclass

import compas.geometry
import cv2 as cv
import numpy as np
import numpy.typing as npt

from chess_vision.camera_calibration import CameraCalibration
from chess_vision.charuco_board import ChArUcoBoard
from chess_vision.geometry import transformation_from_cv

ImageU8 = npt.NDArray[np.uint8]
MarkerIDs = npt.NDArray[np.int32]
CornerCoordinates = npt.NDArray[np.float32]


@typing.final
@dataclass(frozen=True)
class ChArUcoDetection:
    # Transformation to charuco frame from optical frame
    transformation: compas.geometry.Transformation
    # Detected markers
    marker_ids: MarkerIDs
    # Number of detected corners
    corner_count: int
    # RMS Euclidean reprojection error in pixels
    # https://stackoverflow.com/a/79587435/15398307
    reprojection_error: float


@typing.final
class ChArUcoTracker:
    MIN_POSE_CORNERS = 6

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

        # introduced in 4.7
        if hasattr(cv.aruco, "CharucoDetector"):
            self._detector = cv.aruco.CharucoDetector(self.board.board)
            self._detector_params = None
        else:
            self._detector = None
            self._detector_params = cv.aruco.DetectorParameters_create()  # pyright: ignore[reportUnknownMemberType, reportAttributeAccessIssue]

            # works for old/new board wrappers depending on binding version.
            if hasattr(self.board.board, "getDictionary"):
                self._dictionary = self.board.board.getDictionary()
            else:
                self._dictionary = self.board.board.dictionary  # pyright: ignore[reportUnknownMemberType, reportAttributeAccessIssue]

        self._debug_save_image_with_drawn_markers_counter = 0

    def _detect_board(self, frame: ImageU8):
        if self._detector is not None:
            # detectBoard runs detectMarkers if charucoCorners and charucoIds
            # are not provided
            return self._detector.detectBoard(frame)

        marker_corners, marker_ids, _rejected = cv.aruco.detectMarkers(  # pyright: ignore[reportCallIssue] # ty: ignore[no-matching-overload]
            frame,
            self._dictionary,
            parameters=self._detector_params,
        )

        if marker_ids is not None and len(marker_ids) > 0:
            _count, charuco_corners, charuco_ids = cv.aruco.interpolateCornersCharuco(
                marker_corners,
                marker_ids,
                frame,
                self.board.board,
                cameraMatrix=self.camera_calibration.matrix,
                distCoeffs=self.camera_calibration.dist_coeffs,
            )

        return charuco_corners, charuco_ids, marker_corners, marker_ids

    def _match_image_points(
        self, charuco_corners: CornerCoordinates, charuco_ids: MarkerIDs
    ) -> tuple[
        npt.NDArray[np.float32],
        npt.NDArray[np.float32],
    ]:
        if hasattr(self.board.board, "matchImagePoints"):
            return self.board.board.matchImagePoints(charuco_corners, charuco_ids)

        # opencv 4.6
        object_points = np.asarray(
            self.board.board.chessboard_corners, dtype=np.float32
        )[charuco_ids.flatten()]

        image_points = np.asarray(
            charuco_corners,
            dtype=np.float32,
        ).reshape(-1, 2)

        return object_points, image_points

    def detect_pose(
        self,
        frame: ImageU8,
    ) -> tuple[
        ImageU8,
        ChArUcoDetection | None,
    ]:
        charuco_corners, charuco_ids, markerCorners, marker_ids = self._detect_board(
            frame
        )

        marked_frame: ImageU8 = self.draw_debug_frame(
            frame.copy(),
            charuco_corners,
            charuco_ids,
        )

        if self.debug_frame_dump_directory is not None:
            path = self.dump_debug_frame(
                marked_frame,
            )
            print(f"Dumped frame: {path=}")

        if marker_ids is None or len(marker_ids) < 1:
            print("Didn't detect any ArUco markers")
            return marked_frame, None

        if (
            charuco_ids is None
            or charuco_corners is None
            or len(charuco_ids) < self.MIN_POSE_CORNERS
        ):
            print("Didn't detect enough ChArUco corners")
            return marked_frame, None

        object_points, image_points = self._match_image_points(
            charuco_corners,
            charuco_ids,
        )

        success, rvec, tvec = cv.solvePnP(
            object_points,
            image_points,
            self.camera_calibration.matrix,
            self.camera_calibration.dist_coeffs,
        )

        if not success:
            return marked_frame, None

        T = transformation_from_cv(rvec, tvec)

        projected_points, _ = cv.projectPoints(
            object_points,
            rvec,
            tvec,
            self.camera_calibration.matrix,
            self.camera_calibration.dist_coeffs,
        )

        residuals = image_points.reshape(-1, 2) - projected_points.reshape(-1, 2)

        # RMS Euclidean reprojection error in pixels
        reprojection_error = float(np.sqrt(np.mean(np.sum(residuals**2, axis=1))))

        detection = ChArUcoDetection(
            transformation=T,
            marker_ids=marker_ids,
            corner_count=len(charuco_ids),
            reprojection_error=reprojection_error,
        )

        return marked_frame, detection

    def draw_debug_frame(
        self,
        frame: ImageU8,
        charuco_corners: CornerCoordinates | None,
        charuco_ids: MarkerIDs | None,
    ) -> ImageU8:
        if frame.ndim == 2:
            frame = cv.cvtColor(frame, cv.COLOR_GRAY2BGR)  # pyright: ignore[reportAssignmentType] # ty: ignore[invalid-assignment]

        if (
            charuco_ids is not None
            and len(charuco_ids) > 0
            and charuco_corners is not None
        ):
            _ = cv.aruco.drawDetectedCornersCharuco(
                frame,
                charuco_corners,
                charuco_ids,
            )

        return frame

    def dump_debug_frame(
        self,
        frame: ImageU8,
    ):

        if self.debug_frame_dump_directory is None:
            raise RuntimeError(
                "dump debug frame called without debug_frame_dump_directory set"
            )

        path = pathlib.Path(
            self.debug_frame_dump_directory
            / f"frame_{self._debug_save_image_with_drawn_markers_counter:03d}.png"
        )

        self._debug_save_image_with_drawn_markers_counter += 1

        _ = cv.imwrite(str(path), frame)

        return path
