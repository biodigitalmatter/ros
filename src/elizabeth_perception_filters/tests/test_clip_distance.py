import numpy as np
import pytest
from sensor_msgs.msg import Image

from elizabeth_perception_filters.clip_distance import clip_distance
from elizabeth_perception_filters.conversions import image_data_to_array


@pytest.mark.parametrize(
    ("source", "expected"),
    [
        (
            np.array([[0, 100, 200, 500, 1000, 1200]], dtype=np.uint16),
            np.array([[0, 0, 200, 500, 1000, 0]], dtype=np.uint16),
        ),
        (
            np.array([[199, 200, 201, 999, 1000, 1001]], dtype=np.uint16),
            np.array([[0, 200, 201, 999, 1000, 0]], dtype=np.uint16),
        ),
    ],
)
def test_clip_16uc1(source: np.ndarray, expected: np.ndarray) -> None:
    msg = Image()

    msg.height = source.shape[0]
    msg.width = source.shape[1]
    msg.encoding = "16UC1"
    msg.step = msg.width * source.dtype.itemsize
    msg.data = source.tobytes()

    out = clip_distance(msg, min_distance_m=0.2, max_distance_m=1.0)

    np.testing.assert_array_equal(
        image_data_to_array(out, np.dtype(np.uint16)), expected
    )


@pytest.mark.parametrize(
    ("source", "expected"),
    [
        (
            np.array([[0.1, 0.21, 0.5, 1.2, 3.0]], dtype=np.float32),
            np.array([[0.0, 0.21, 0.5, 1.2, 0.0]], dtype=np.float32),
        ),
        (
            np.array([[-1.2, 3.3, 0.15, 1.2, 3.0]], dtype=np.float32),
            np.array([[0.0, 0.0, 0.0, 1.2, 0.0]], dtype=np.float32),
        ),
    ],
)
def test_clip_32fc1(source: np.ndarray, expected: np.ndarray) -> None:
    msg = Image()

    msg.height = source.shape[0]
    msg.width = source.shape[1]
    msg.encoding = "32FC1"
    msg.step = msg.width * source.dtype.itemsize
    msg.data = source.tobytes()

    out = clip_distance(msg, min_distance_m=0.2, max_distance_m=2.0)

    np.testing.assert_array_equal(image_data_to_array(out, np.float32), expected)


def test_unsupported_encoding_raises() -> None:
    msg_data = np.array([[1, 2]], dtype=np.uint8)

    msg = Image()

    msg.height = msg_data.shape[0]
    msg.width = msg_data.shape[1]
    msg.encoding = "mono8"
    msg.step = msg.width * msg_data.dtype.itemsize
    msg.data = msg_data.tobytes()

    with pytest.raises(ValueError):
        _ = clip_distance(msg, min_distance_m=0.2, max_distance_m=1.0)
