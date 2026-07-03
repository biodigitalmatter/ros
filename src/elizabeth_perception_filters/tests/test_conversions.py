import numpy as np
import pytest
from sensor_msgs.msg import Image

from elizabeth_perception_filters.conversions import (
    array_to_image_data,
    image_data_to_array,
)


def test_image_data_to_array_returns_view() -> None:
    msg = Image()

    msg_data = np.array(
        [[100, 200], [300, 400]],
        dtype=np.uint16,
    )

    msg.height = msg_data.shape[0]
    msg.width = msg_data.shape[1]
    msg.encoding = "16UC1"
    msg.step = msg.width * msg_data.dtype.itemsize
    msg.data = msg_data.tobytes()

    arr = image_data_to_array(msg, np.uint16)

    arr[0, 0] = 1234

    raw = np.ndarray(
        shape=(msg.height, msg.width),
        dtype=np.uint16,
        buffer=msg.data,
        strides=(msg.step, np.dtype(np.uint16).itemsize),
    )

    assert raw[0, 0] == 1234


def test_image_data_to_array_handles_padding() -> None:
    msg = Image()
    msg.height = 2
    msg.width = 2
    msg.encoding = "16UC1"
    msg.step = 6

    # Each row:
    # 2 uint16 pixels = 4 bytes
    # + 2 bytes padding
    msg.data = bytearray(
        [
            100,
            0,
            200,
            0,
            0xAA,
            0xBB,
            44,
            1,
            144,
            1,
            0xCC,
            0xDD,
        ]
    )

    arr = image_data_to_array(msg, np.uint16)

    np.testing.assert_array_equal(
        arr,
        np.array(
            [[100, 200], [300, 400]],
            dtype=np.uint16,
        ),
    )


def test_array_to_image_data_roundtrip() -> None:
    msg = Image()
    msg.height = 2
    msg.width = 2
    msg.encoding = "16UC1"
    msg.step = 4
    msg.data = bytearray(8)

    source = np.array(
        [[100, 200], [300, 400]],
        dtype=np.uint16,
    )

    array_to_image_data(source, msg)

    result = image_data_to_array(msg, np.uint16)

    np.testing.assert_array_equal(result, source)


def test_array_to_image_data_roundtrip_preserves_padding() -> None:
    msg = Image()
    msg.height = 2
    msg.width = 2
    msg.encoding = "16UC1"
    msg.step = 6

    msg.data = bytearray(
        [
            0,
            0,
            0,
            0,
            0xAA,
            0xBB,
            0,
            0,
            0,
            0,
            0xCC,
            0xDD,
        ]
    )

    source = np.array(
        [[100, 200], [300, 400]],
        dtype=np.uint16,
    )

    array_to_image_data(source, msg)

    result = image_data_to_array(msg, np.uint16)

    np.testing.assert_array_equal(result, source)

    assert bytes(msg.data[4:6]) == b"\xaa\xbb"
    assert bytes(msg.data[10:12]) == b"\xcc\xdd"


def test_array_to_image_data_rejects_wrong_shape() -> None:
    msg = Image()
    msg.height = 2
    msg.width = 2
    msg.step = 4
    msg.data = bytearray(8)

    source = np.zeros((3, 2), dtype=np.uint16)

    with pytest.raises(ValueError):
        array_to_image_data(source, msg)
