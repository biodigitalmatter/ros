from packaging.version import Version
import cv2.aruco
# import cv2.aruco.CharucoBoard


def _create_board(**kwargs):
    if Version(cv2.__version__) <= Version("4.7.0"):
        return cv2.aruco.CharucoBoard.create(**kwargs)
    else:
        x = kwargs.pop("squaresX")
        y = kwargs.pop("squaresY")
        return cv2.aruco.CharucoBoard((x, y), **kwargs)


large = _create_board(
    squaresX=9,
    squaresY=14,
    squareLength=0.04,
    markerLength=0.03,
    dictionary=cv2.aruco.getPredefinedDictionary(cv2.aruco.DICT_5X5_100),
)

# https://github.com/yumashino/Camera-Calibration-with-ChArUco-Board/blob/main/sample_calibration_input.yaml
sample_calibration_video = _create_board(
    squaresX=9,
    squaresY=5,
    squareLength=0.038,
    markerLength=0.03,
    dictionary=cv2.aruco.getPredefinedDictionary(cv2.aruco.DICT_6X6_250),
)
