import copy

import numpy as np
from sensor_msgs.msg import Image


def clip_depth_image(msg: Image, min_distance_m: float, max_distance_m: float) -> Image:
    out = copy.copy(msg)

    match msg.encoding:
        case "16UC1":
            dtype = np.dtype(np.uint16)

            depth = image_data_to_array(msg, dtype).copy()

            min_mm = int(min_distance_m * 1000.0)
            max_mm = int(max_distance_m * 1000.0)

            invalid = (depth == 0) | (depth < min_mm) | (depth > max_mm)

            depth[invalid] = 0

        case "32FC1":
            dtype = np.dtype(np.float32)

            depth = image_data_to_array(msg, dtype).copy()

            invalid = (
                (~np.isfinite(depth))
                | (depth < min_distance_m)
                | (depth > max_distance_m)
            )

            depth[invalid] = 0.0

        case _:
            raise ValueError(f"Unsupported depth encoding: {msg.encoding}")

    # since padding might have been removed
    out.step = msg.width * np.dtype(dtype).itemsize

    out.data = depth.tobytes()

    return out


def image_data_to_array(
    msg: Image,
    dtype: np.dtype | type[np.uint16] | type[np.float32],
) -> np.ndarray:
    #   16UC1  -> np.uint16  -> 2 bytes per pixel
    #   32FC1  -> np.float32 -> 4 bytes per pixel
    bytes_per_pixel = np.dtype(dtype).itemsize

    if msg.step % bytes_per_pixel != 0:
        raise ValueError(
            f"Image step {msg.step} is not divisible by bytes per pixel "
            f"{bytes_per_pixel} for encoding {msg.encoding}"
        )

    expected_step = msg.width * bytes_per_pixel

    # no padding
    if msg.step == expected_step:
        return np.frombuffer(msg.data, dtype=dtype).reshape(msg.height, msg.width)

    # handles row padding
    row_stride = msg.step // bytes_per_pixel

    if row_stride < msg.width:
        raise ValueError(
            f"Image row stride {row_stride} is smaller than width {msg.width}"
        )

    return (
        np.frombuffer(msg.data, dtype=dtype)
        # keep only up till msg.width (rest is padding)
        .reshape(msg.height, row_stride)[:, : msg.width]
    )
