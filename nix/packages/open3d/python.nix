{
  lib,
  buildPythonPackage,
  pytestCheckHook,

  open3d,
  python,

  # deps
  configargparse,
  dash,
  flask,
  nbformat,
  numpy,
  werkzeug,

  # tests
  scipy,

  withCuda ? false,
}:
let
  open3dCpu = open3d.override {
    withPythonBindings = true;
  };

  open3dCuda = open3d.override {
    withCuda = true;
    withPythonBindings = true;
  };

  pythonSource = if withCuda then open3dCuda.python else open3dCpu.python;
in
buildPythonPackage {
  inherit (open3d) version;
  pname = if withCuda then "open3d" else "open3d-cpu";

  src = pythonSource;

  # package.nix has already built everything.
  pyproject = false;
  dontBuild = true;

  dependencies = [
    configargparse
    dash
    flask
    nbformat
    numpy
    werkzeug
  ];

  nativeCheckInputs = [
    pytestCheckHook
    scipy
  ];

  postPatch = lib.optionalString withCuda ''
    # add the CPU fallback produced by the CPU Open3D build.
    cp -a ${open3dCpu.python}/open3d/cpu open3d/cpu
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/${python.sitePackages}"
    cp -a open3d "$out/${python.sitePackages}/"

    runHook postInstall
  '';

  pythonImportsCheck = [
    "open3d"
  ];

  disabledTestPaths = [
    # skip benchmarks
    "benchmarks/*"

    # requires networking
    "test/data/test_data.py"
    "test/test_octree.py::test_octree_visualize"
    "test/test_octree.py::test_octree_voxel_grid_convert"
    "test/test_octree.py::test_locate_leaf_node"
    "test/io/test_pathlib.py::test_pathlib_support"
    "test/t/io/test_noise.py::test_apply_depth_noise_model"
    "test/test_color_map_optimization.py::test_color_map"

    # requires torch even when -DBUILD_PYTORCH_OPS=OFF
    "test/ml_ops/test_ragged_tensor.py"

    # The test matrix is singular. OpenBLAS GETRF reports a zero pivot for
    # Float32, while this test assumes the factorization succeeds.
    "test/core/test_linalg.py::test_lu[dtype2-device0]"
  ];

}
