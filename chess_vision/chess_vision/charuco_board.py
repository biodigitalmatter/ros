from cv2 import aruco


class ChArUcoBoard:
    def __init__(
        self, name, squaresX, squaresY, squareLength, markerLength, dictionary
    ):
        self.dictionary = aruco.getPredefinedDictionary(dictionary)

        self.board = aruco.CharucoBoard(
            (squaresX, squaresY), squareLength, markerLength, self.dictionary
        )

    @classmethod
    def from_board_parameters_dict(cls, key):
        return cls(key, **BOARD_PARAMETERS[key])


BOARD_PARAMETERS = {
    "large": {
        "squaresX": 9,
        "squaresY": 14,
        "squareLength": 0.04,
        "markerLength": 0.03,
        "dictionary": aruco.DICT_5X5_100,
    },
    # https://github.com/yumashino/Camera-Calibration-with-ChArUco-Board/blob/main/sample_calibration_input.yaml
    "sample_calibration_video_board": {
        "squaresX": 9,
        "squaresY": 5,
        "squareLength": 0.038,
        "markerLength": 0.03,
        "dictionary": aruco.DICT_6X6_250,
    },
}
