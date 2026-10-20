import typing
from collections.abc import Iterator
from dataclasses import dataclass

from builtin_interfaces.msg import Time
from compas.geometry import Transformation
from rclpy.duration import Duration
from rclpy.time import Time as RclpyTime
from tf2_msgs.msg import TFMessage
from tf2_ros import Buffer

from chess_vision_ros.bag import BagReader
from chess_vision_ros.conversions import transformation_from_transform


@typing.final
@dataclass(frozen=True)
class StampedTransformation:
    timestamp_ns: int
    transformation: Transformation


class BagTransformBuffer:
    TF_CACHE_MARGIN_NS = 10_000_000_000

    def __init__(self, bag: BagReader):
        self._bag = bag
        self._buffer = Buffer(
            cache_time=Duration(nanoseconds=bag.duration_ns + self.TF_CACHE_MARGIN_NS)
        )

        self._load()

    def _load(self) -> None:
        for item in self._bag.messages(("/tf", "/tf_static")):
            assert isinstance(item.message, TFMessage)

            for transform in item.message.transforms:
                if item.topic == "/tf_static":
                    self._buffer.set_transform_static(transform, "rosbag")
                else:
                    self._buffer.set_transform(transform, "rosbag")

    def lookup_transform(
        self,
        target_frame: str,
        source_frame: str,
        timestamp_ns: int,
    ) -> Transformation:
        time = RclpyTime(nanoseconds=timestamp_ns)
        transform = self._buffer.lookup_transform(target_frame, source_frame, time)

        return transformation_from_transform(transform.transform)

    @staticmethod
    def _time_to_ns(time: Time) -> int:
        return time.sec * 1_000_000_000 + time.nanosec

    def transforms(
        self,
        parent_frame: str,
        child_frame: str,
    ) -> Iterator[StampedTransformation]:
        for item in self._bag.messages(("/tf",)):
            assert isinstance(item.message, TFMessage)

            for transform in item.message.transforms:
                if (
                    transform.header.frame_id == parent_frame
                    and transform.child_frame_id == child_frame
                ):
                    yield StampedTransformation(
                        timestamp_ns=self._time_to_ns(transform.header.stamp),
                        transformation=transformation_from_transform(
                            transform.transform
                        ),
                    )
