import math

import numpy as np
import pytest
from elizabeth_perception_filters.depth_image_filters import (
    clip_depth_image,
    image_data_to_array,
)
from sensor_msgs.msg import Image


def make_image(data: np.ndarray, encoding: str, *, step: int | None = None) -> Image:
    msg = Image()
    msg.header.frame_id = "depth_frame"
    msg.header.stamp.sec = 123
    msg.header.stamp.nanosec = 456
    msg.height = data.shape[0]
    msg.width = data.shape[1]
    msg.encoding = encoding
    msg.is_bigendian = False
    msg.step = step if step is not None else msg.width * data.dtype.itemsize
    msg.data = data.tobytes()
    return msg


def read_image(msg: Image, dtype: np.dtype) -> np.ndarray:
    return np.frombuffer(msg.data, dtype=dtype).reshape(msg.height, msg.width)


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
    msg = make_image(source, "16UC1")

    out = clip_depth_image(msg, min_distance_m=0.2, max_distance_m=1.0)

    np.testing.assert_array_equal(read_image(out, np.uint16), expected)


@pytest.mark.parametrize(
    ("source", "expected"),
    [
        (
            np.array([[0.1, 0.2, 0.5, 1.0, 1.2]], dtype=np.float32),
            np.array([[0.0, 0.2, 0.5, 1.0, 0.0]], dtype=np.float32),
        ),
        (
            np.array([[math.nan, math.inf, -math.inf, 0.7]], dtype=np.float32),
            np.array([[0.0, 0.0, 0.0, 0.7]], dtype=np.float32),
        ),
    ],
)
def test_clip_32fc1(source: np.ndarray, expected: np.ndarray) -> None:
    msg = make_image(source, "32FC1")

    out = clip_depth_image(msg, min_distance_m=0.2, max_distance_m=1.0)

    np.testing.assert_array_equal(read_image(out, np.float32), expected)


def test_preserves_metadata_and_does_not_mutate_input() -> None:
    source = np.array([[100, 200], [300, 400]], dtype=np.uint16)
    msg = make_image(source, "16UC1")
    original_data = bytes(msg.data)

    out = clip_depth_image(msg, min_distance_m=0.2, max_distance_m=1.0)

    assert bytes(msg.data) == original_data
    assert out.header == msg.header
    assert out.height == msg.height
    assert out.width == msg.width
    assert out.encoding == msg.encoding
    assert out.is_bigendian == msg.is_bigendian
    assert out.step == msg.width * np.dtype(np.uint16).itemsize


def test_row_padding_is_removed() -> None:
    # width is 3, but each stored row contains 5 uint16 values.
    padded = np.array(
        [
            [100, 200, 300, 9999, 9999],
            [400, 500, 600, 9999, 9999],
        ],
        dtype=np.uint16,
    )

    msg = Image()
    msg.height = 2
    msg.width = 3
    msg.encoding = "16UC1"
    msg.is_bigendian = False
    msg.step = 5 * np.dtype(np.uint16).itemsize
    msg.data = padded.tobytes()

    out = clip_depth_image(msg, min_distance_m=0.2, max_distance_m=0.5)

    assert out.step == 3 * np.dtype(np.uint16).itemsize
    np.testing.assert_array_equal(
        read_image(out, np.uint16),
        np.array([[0, 200, 300], [400, 500, 0]], dtype=np.uint16),
    )


def test_unsupported_encoding_raises() -> None:
    msg = make_image(np.array([[1, 2]], dtype=np.uint8), "mono8")

    with pytest.raises(ValueError, match="Unsupported depth encoding"):
        clip_depth_image(msg, min_distance_m=0.2, max_distance_m=1.0)


def test_row_stride_smaller_than_width_raises() -> None:
    msg = Image()
    msg.height = 1
    msg.width = 4
    msg.encoding = "16UC1"
    msg.step = 3 * np.dtype(np.uint16).itemsize
    msg.data = np.zeros((1, 3), dtype=np.uint16).tobytes()

    with pytest.raises(ValueError, match="row stride .* smaller than width"):
        image_data_to_array(msg, np.dtype(np.uint16))
