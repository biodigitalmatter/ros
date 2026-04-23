import numpy as np
import pytest
from chess_vision.eye_in_hand_solver import (
    EyeInHandSolver,
    Sample,
)
from compas.geometry import Frame, Transformation, Vector
from compas.tolerance import TOL


def test_sample_as_cv_input_extracts_rotation_and_translation() -> None:
    f = Frame(point=[100, 200, 300])
    _ = f.rotate(angle=0.3, axis=Vector.Zaxis())
    gripper2base = Transformation.from_frame(f)

    f = Frame(point=[10, 20, 30])
    _ = f.rotate(angle=-0.2, axis=Vector.Xaxis())
    target2cam = Transformation.from_frame(f)

    sample = Sample(gripper2base=gripper2base, target2cam=target2cam)

    R_g2b, t_g2b, R_t2c, t_t2c = sample.as_cv_input()

    assert TOL.is_allclose(R_g2b, gripper2base.rotation)

    np.testing.assert_allclose(t_g2b, np.asarray(gripper2base.translation_vector))

    assert TOL.is_allclose(R_t2c, target2cam.rotation)

    np.testing.assert_allclose(t_t2c, np.asarray(target2cam.translation_vector))


def test_solver_rejects_too_few_samples() -> None:
    solver = EyeInHandSolver()

    with pytest.raises(RuntimeError, match="Not enough samples"):
        solver.solve()
