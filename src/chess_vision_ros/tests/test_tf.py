from pathlib import Path

import pytest
from compas.geometry import Transformation

from chess_vision_ros.bag import BagReader
from chess_vision_ros.tf import BagTransformBuffer


@pytest.fixture(scope="module")
def tf_bag_reader(tf_rosbag_path: Path) -> BagReader:
    return BagReader(tf_rosbag_path)


@pytest.fixture(scope="module")
def tf_buffer(tf_bag_reader: BagReader) -> BagTransformBuffer:
    return BagTransformBuffer(tf_bag_reader)


def test_transforms_returns_recorded_edge(tf_buffer: BagTransformBuffer) -> None:

    transforms = list(tf_buffer.transforms("link_1", "tool0"))

    assert all(t.timestamp_ns > 0 for t in transforms)

    assert all(isinstance(t.transformation, Transformation) for t in transforms)


def test_transforms_returns_empty_for_unknown_edge(
    tf_buffer: BagTransformBuffer,
) -> None:
    transforms = list(
        tf_buffer.transforms(
            "does_not_exist",
            "does_not_exist2",
        )
    )

    assert transforms == []


def test_dynamic_transform_changes(tf_buffer: BagTransformBuffer) -> None:
    transforms = list(tf_buffer.transforms("link_1", "link_2"))

    assert len(transforms) > 1
    assert transforms[0].transformation != transforms[-1].transformation


def test_lookup_transform_resolves_chain(
    tf_buffer: BagTransformBuffer,
) -> None:
    transforms = list(tf_buffer.transforms("link_1", "link_2"))
    timestamp_ns = transforms[len(transforms) // 2].timestamp_ns

    transformation = tf_buffer.lookup_transform(
        target_frame="base_link",
        source_frame="tool0",
        timestamp_ns=timestamp_ns,
    )

    assert isinstance(transformation, Transformation)


def test_lookup_transform_retains_early_history(
    tf_buffer: BagTransformBuffer,
) -> None:
    transforms = list(tf_buffer.transforms("link_1", "link_2"))
    timestamp_ns = transforms[0].timestamp_ns

    transformation = tf_buffer.lookup_transform(
        target_frame="base_link",
        source_frame="tool0",
        timestamp_ns=timestamp_ns,
    )

    assert isinstance(transformation, Transformation)


def test_lookup_transform_uses_static_transforms(
    tf_buffer: BagTransformBuffer,
) -> None:
    observations = list(tf_buffer.transforms("link_1", "link_2"))
    timestamp_ns = observations[len(observations) // 2].timestamp_ns

    transformation = tf_buffer.lookup_transform(
        target_frame="map",
        source_frame="tool0",
        timestamp_ns=timestamp_ns,
    )

    assert isinstance(transformation, Transformation)
