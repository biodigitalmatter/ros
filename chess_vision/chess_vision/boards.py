from cv2 import aruco

large = aruco.CharucoBoard_create(
  squaresX=9,
  squaresY=14,
  squareLength=0.04,
  markerLength=0.03,
  dictionary=aruco.getPredefinedDictionary(aruco.DICT_5X5_100)
)

# https://github.com/yumashino/Camera-Calibration-with-ChArUco-Board/blob/main/sample_calibration_input.yaml
sample_calibration_video = aruco.CharucoBoard_create(
  squaresX=9,
  squaresY=5,
  squareLength=.038,
  markerLength=.03,
  dictionary=aruco.getPredefinedDictionary(aruco.DICT_6X6_250))
