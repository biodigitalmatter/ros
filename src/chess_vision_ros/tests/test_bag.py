from pathlib import Path

import pytest
from sensor_msgs.msg import Image

from chess_vision_ros.bag import BagReader


@pytest.fixture
def bag_reader(charuco_rosbag_path: Path) -> BagReader:
    return BagReader(charuco_rosbag_path)


def test_topics(bag_reader: BagReader) -> None:

    assert bag_reader.topics == {"/topic_video": "sensor_msgs/msg/Image"}


def test_duration_ns(bag_reader: BagReader) -> None:

    assert isinstance(bag_reader.duration_ns, int)
    assert bag_reader.duration_ns > 0


def test_messages_filters_and_derserializes(bag_reader: BagReader) -> None:
    messages = list(bag_reader.messages(("/topic_video",)))

    assert messages

    assert all(message.topic == "/topic_video" for message in messages)
    assert all(isinstance(message.message, Image) for message in messages)


def test_messages_can_be_iterated_multiple_times(bag_reader: BagReader):
    first = list(bag_reader.messages(("/topic_video")))
    second = list(bag_reader.messages(("/topic_video")))

    assert [(m.topic, m.timestamp_ns) for m in first] == [
        (m.topic, m.timestamp_ns) for m in second
    ]


def test_messages_without_filter_returns_all_messages(bag_reader: BagReader) -> None:

    messages = list(bag_reader.messages())

    assert messages
    assert all(message.topic == "/topic_video" for message in messages)


def test_messages_with_empty_filter_returns_no_messages(bag_reader: BagReader) -> None:

    assert list(bag_reader.messages(())) == []
