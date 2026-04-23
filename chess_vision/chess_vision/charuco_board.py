from dataclasses import dataclass
from cv2 import aruco


class ChArUcoBoard:
    def __init__(
        self,
        name: str,
        squaresX: int,
        squaresY: int,
        squareLength: float,
        markerLength: float,
        dictionary: int,
    ):
        self.dictionary: aruco.Dictionary = aruco.getPredefinedDictionary(dictionary)

        self.board: aruco.CharucoBoard = aruco.CharucoBoard(
            (squaresX, squaresY), squareLength, markerLength, self.dictionary
        )

    @classmethod
    def from_board_parameters_dict(cls, key: str):
        params = BOARD_PARAMETERS[key]
        return cls(
            key,
            params.squaresX,
            params.squaresY,
            params.squareLength,
            params.markerLength,
            params.dictionary,
        )


@dataclass
class BoardParameters:
    squaresX: int
    squaresY: int
    squareLength: float
    markerLength: float
    dictionary: int


BOARD_PARAMETERS = {
    "large": BoardParameters(9, 14, 0.04, 0.03, aruco.DICT_5X5_100),
    # https://github.com/yumashino/Camera-Calibration-with-ChArUco-Board/blob/main/sample_calibration_input.yaml
    "sample_calibration_video_board": BoardParameters(
        9, 5, 0.038, 0.03, aruco.DICT_6X6_250
    ),
}
