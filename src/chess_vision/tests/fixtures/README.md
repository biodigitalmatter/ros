# sample_calibration_video

Downloaded from
[github:yumashino/Camera-Calibration-With-ChArUco-Board](https://github.com/yumashino/Camera-Calibration-with-ChArUco-Board/blob/7cf0055a402c5ae897ede39877ec9f07802bdc70/sample_calibration_video.mp4)
(MIT license)

``` sh
curl -LO https://github.com/yumashino/Camera-Calibration-with-ChArUco-Board/blob/7cf0055a402c5ae897ede39877ec9f07802bdc70/sample_calibration_video.mp4
```

## create bag from video

``` sh
ros2 run ros2_utils_tool tool_video_to_bag ./sample_calibration_video.mp4 ./rosbag
```
