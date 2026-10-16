import math

import pytest
from compas.geometry import Rotation, Transformation, Translation, Vector

from chess_vision_ros.eye_in_hand import _poses_differ_p


@pytest.mark.parametrize(
    ("previous", "current", "expected"),
    [
        # identity
        (Transformation(), Transformation(), False),
        # Tr below
        (Transformation(), Translation.from_vector([0.01, 0.0, 0.0]), False),
        # Tr above
        (Transformation(), Translation.from_vector([0.03, 0.0, 0.0]), True),
        # R below
        (
            Transformation(),
            Rotation.from_axis_and_angle(
                Vector.Zaxis(),
                math.radians(2),
            ),
            False,
        ),
        # R above
        (
            Transformation(),
            Rotation.from_axis_and_angle(
                Vector.Zaxis(),
                math.radians(10),
            ),
            True,
        ),
        # R below and Tr above
        (
            Transformation(),
            Translation.from_vector([0.03, 0.0, 0.0])
            * Rotation.from_axis_and_angle(
                Vector.Zaxis(),
                math.radians(2),
            ),
            True,
        ),
        # both R and Tr below
        (
            Transformation(),
            Translation.from_vector(
                [
                    0.01,
                    0.0,
                    0.0,
                ]
            )
            * Rotation.from_axis_and_angle(Vector.Zaxis(), math.radians(2)),
            False,
        ),
        # relative Tr
        # This tests compas more than my code..
        (
            Translation.from_vector(
                [
                    10.0,
                    20.0,
                    30.0,
                ]
            ),
            Translation.from_vector(
                [
                    10.01,
                    20.0,
                    30.0,
                ]
            ),
            False,
        ),
        (
            # Tr on threshold
            Transformation(),
            Translation.from_vector([0.02, 0.0, 0.0]),
            True,
        ),
    ],
)
def test_poses_differ_p(
    previous: Transformation,
    current: Transformation,
    expected: bool,
) -> None:
    assert (
        _poses_differ_p(
            previous, current, min_translation=0.02, min_rotation=math.radians(5)
        )
        is expected
    )
