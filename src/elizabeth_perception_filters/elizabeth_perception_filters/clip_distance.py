import numpy as np
from sensor_msgs.msg import Image

from elizabeth_perception_filters.conversions import image_data_to_array


def clip_distance(msg: Image, min_distance_m: float, max_distance_m: float) -> Image:
    """Clips image in msg by mutating input msg."""
    match msg.encoding:
        # u16 value for black to white
        case "16UC1":
            dtype = np.dtype(np.uint16)
            min_value = min_distance_m * 1000.0
            max_value = max_distance_m * 1000.0

        # f32 values
        case "32FC1":
            dtype = np.dtype(np.float32)
            min_value = min_distance_m
            max_value = max_distance_m
        case _:
            raise ValueError(f"Unsupported depth encoding: {msg.encoding}")

    depth = image_data_to_array(msg, dtype)

    # hopefully works out ok for uint16
    invalid = (~np.isfinite(depth)) | (depth < min_value) | (depth > max_value)

    depth[invalid] = 0

    return msg
