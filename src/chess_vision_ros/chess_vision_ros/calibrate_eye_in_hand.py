import math
from pathlib import Path

import click

from chess_vision.eye_in_hand import HandEyeMethod, calibrate_eye_in_hand
from chess_vision_ros.bag import BagReader
from chess_vision_ros.eye_in_hand import (
    EyeInHandCalibration,
    EyeInHandConfig,
    eye_in_hand_quality,
    eye_in_hand_samples_from_bag,
)


@click.command()
@click.argument(
    "bag",
    type=click.Path(exists=True, file_okay=False, path_type=Path),
)
@click.option(
    "--output",
    required=True,
    type=click.Path(dir_okay=False, path_type=Path),
    help="Output COMPAS JSON path.",
)
@click.option("--base-frame", default="map", show_default=True)
@click.option("--gripper-frame", default="tool0", show_default=True)
@click.option(
    "--camera-frame",
    default="extruder_d405_color_optical_frame",
    show_default=True,
)
@click.option("--target-frame", default="charuco_board", show_default=True)
@click.option(
    "--method",
    type=click.Choice(
        [method.name.lower() for method in HandEyeMethod], case_sensitive=False
    ),
    default=HandEyeMethod.TSAI.name.lower(),
    show_default=True,
)
@click.option(
    "--min-translation", type=click.FloatRange(min=0), default=0.02, show_default=True
)
@click.option(
    "--min-rotation-deg", type=click.FloatRange(min=0), default=5.0, show_default=True
)
def main(
    bag: Path,
    output: Path,
    base_frame: str,
    gripper_frame: str,
    camera_frame: str,
    target_frame: str,
    method: str,
    min_translation: float,
    min_rotation_deg: float,
) -> None:
    """Calibrate an eye-in-hand camera from BAG."""
    if output.exists():
        raise click.BadParameter("output already exists", param_hint="--output")
    if not output.parent.is_dir():
        raise click.BadParameter(
            "output directory does not exist", param_hint="--output"
        )

    config = EyeInHandConfig(
        base_frame=base_frame,
        gripper_frame=gripper_frame,
        camera_frame=camera_frame,
        target_frame=target_frame,
        method=HandEyeMethod[method.upper()],
        min_translation=min_translation,
        min_rotation=math.radians(min_rotation_deg),
    )

    try:
        samples = eye_in_hand_samples_from_bag(BagReader(bag), config)
        result = calibrate_eye_in_hand(samples, method=config.method)
        quality = eye_in_hand_quality(samples, result)
        calibration = EyeInHandCalibration(
            config=config,
            sample_count=len(samples),
            result=result,
            quality=quality,
        )
        calibration.to_json(str(output), pretty=True, minimal=True)
    except (OSError, RuntimeError, ValueError) as error:
        raise click.ClickException(str(error)) from error

    click.echo(f"Used {len(samples)} samples")
    click.echo(f"Method: {result.method.name}")
    click.echo(f"Target consistency RMS: {quality.rms_mm:.2f} mm")
    click.echo(f"Target consistency p95: {quality.p95_mm:.2f} mm")
    click.echo(f"Wrote calibration: {output}")


if __name__ == "__main__":
    main()
