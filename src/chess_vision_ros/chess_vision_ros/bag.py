from collections.abc import Collection, Iterator
from dataclasses import dataclass
from pathlib import Path

from rclpy.serialization import deserialize_message
from rosbag2_py import (
    ConverterOptions,
    SequentialReader,
    StorageFilter,
    StorageOptions,
)
from rosidl_runtime_py.utilities import get_message


@dataclass(frozen=True)
class BagMessage:
    topic: str
    timestamp_ns: int
    message: object


class BagReader:
    """Yields from bag with topic filter.

    Based on https://github.com/ros2/rosbag2/blob/jazzy/rosbag2_examples/rosbag2_examples_py/rosbag2_examples_py/rosbag2csv.py
    """

    def __init__(self, path: Path):
        self.path = path
        self._topics: dict[str, str] | None = None
        self._metadata = None

    def _open_reader(self) -> SequentialReader:
        reader = SequentialReader()
        reader.open(
            StorageOptions(uri=str(self.path)),
            ConverterOptions("", ""),
        )
        return reader

    @property
    def metadata(self):
        if self._metadata is None:
            reader = self._open_reader()
            try:
                self._metadata = reader.get_metadata()
            finally:
                reader.close()

        return self._metadata

    @property
    def duration_ns(self) -> int:
        return self.metadata.duration.nanoseconds

    @property
    def topics(self) -> dict[str, str]:
        return {
            topic_info.topic_metadata.name: topic_info.topic_metadata.type
            for topic_info in self.metadata.topics_with_message_count
        }

    def messages(self, topics: Collection[str] | None = None) -> Iterator[BagMessage]:
        if topics is not None and len(topics) == 0:
            return

        reader = self._open_reader()

        if topics is not None:
            reader.set_filter(StorageFilter(topics=list(topics)))

        try:
            while reader.has_next():
                topic, data, timestamp_ns = reader.read_next()

                msg_type = get_message(self.topics[topic])
                msg = deserialize_message(data, msg_type)

                yield BagMessage(topic=topic, timestamp_ns=timestamp_ns, message=msg)
        finally:
            reader.close()
