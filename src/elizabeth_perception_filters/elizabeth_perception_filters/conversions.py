import numpy as np
import numpy.typing as npt
from sensor_msgs.msg import Image


def image_data_to_array(
    msg: Image, dtype: npt.DTypeLike
) -> npt.NDArray[np.uint16] | npt.NDArray[np.float32]:
    dtype = np.dtype(dtype)
    bytes_per_pixel = dtype.itemsize

    if msg.step < msg.width * bytes_per_pixel:
        raise ValueError(f"Image {msg.step=} is too small for {msg.width=}")

    if msg.step % bytes_per_pixel != 0:
        raise ValueError(f"Image {msg.step=} is not divisible by {bytes_per_pixel}")

    # view with no padding
    arr = np.ndarray(
        shape=(msg.height, msg.width),
        dtype=dtype,
        buffer=msg.data,
        strides=(msg.step, bytes_per_pixel),
    )

    if not arr.flags.writeable:
        raise ValueError("Image data buffer not writeable")

    return arr


def array_to_image_data(
    arr: npt.NDArray[np.uint16] | npt.NDArray[np.float32],
    msg: Image,
) -> None:
    dtype = arr.dtype
    bytes_per_pixel = dtype.itemsize

    if arr.shape != (msg.height, msg.width):
        raise ValueError(f"{arr.shape=} does not match {msg.height=}x{msg.width=}")

    if msg.step < msg.width * bytes_per_pixel:
        raise ValueError(f"Image {msg.step=} is too small for {msg.width=}")

    if msg.step % bytes_per_pixel != 0:
        raise ValueError(f"Image {msg.step=} is not divisible by {bytes_per_pixel}")

    dest = np.ndarray(
        shape=(msg.height, msg.width),
        dtype=dtype,
        buffer=msg.data,
        strides=(msg.step, bytes_per_pixel),
    )

    if not dest.flags.writeable:
        raise ValueError("Image data buffer not writeable")

    dest[...] = arr
