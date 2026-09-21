{
  lib,
  stdenv,

  callPackage,
  fetchFromGitHub,
  fetchpatch2,
  replaceVars,
  runCommand,
  symlinkJoin,
  testers,
  writeTextDir,

  debug ? false,
  pythonSupport ? true,
  realsenseSupport ? true,
  withCuda ? true,

  assimp,
  cmake,
  cppzmq,
  cudaPackages,
  curl,
  eigen,
  embree,
  fmt,
  git,
  glew,
  glfw,
  gtest,
  jsoncpp,
  libjpeg,
  liblzf,
  libpng,
  librealsense,
  libtiff,
  libusb1,
  minizip,
  msgpack-cxx,
  nanoflann,
  ninja,
  openblas,
  openssl,
  pkg-config,
  pythonPackages,
  qhull,
  tbb,
  tinyobjloader,
  vtk,
  zeromq,
  zlib,
}:

let
  cutlass133 = callPackage ./cutlass.nix { };
  cudaToolkitRoot = symlinkJoin {
    name = "open3d-cuda-toolkit-root";
    paths = [
      cudaPackages.cudatoolkit
      cudaPackages.libcublas.static
      cudaPackages.libcusolver.static
      cudaPackages.libcusparse.static
      cudaPackages.libnpp.static
    ];
  };

  directxHeaders = fetchFromGitHub {
    owner = "microsoft";
    repo = "DirectX-Headers";
    tag = "v1.606.3";
    hash = "sha256-D3LDBWKCi09dR21i9Z53Nox9fco4FThomNRIoKn502Q=";
  };

  directxMath = fetchFromGitHub {
    owner = "microsoft";
    repo = "DirectXMath";
    tag = "may2022";
    hash = "sha256-4zlqFTJbrTxDlOOI0p2lX5MFmo/gabRSmGgfOep/PbU=";
  };

  openblas32 = openblas.override { blas64 = false; };

  poissonRecon = fetchFromGitHub {
    owner = "isl-org";
    repo = "Open3D-PoissonRecon";
    rev = "90f3f064e275b275cff445881ecee5a7c495c9e0";
    hash = "sha256-0cHy3KxvhiJxVrVh/j1FcFMy60o5mQedIapZrOjKhQo=";
  };

  poissonReconInclude = runCommand "open3d-poissonrecon-include" { } ''
    mkdir -p $out
    ln -s ${poissonRecon} $out/PoissonRecon
  '';

  stdgpu = callPackage ./stdgpu.nix { };

  tinygltf = callPackage ./tinygltf-v2.nix { };

  uvatlas = fetchFromGitHub {
    owner = "microsoft";
    repo = "UVAtlas";
    tag = "may2022";
    hash = "sha256-BP2hkEexo1E0sL43pYKsPhCsP+t7ffupVad06ZctvXs=";
  };

  cmakeFindLibLzf = writeTextDir "cmake/Findliblzf.cmake" ''
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(liblzf QUIET IMPORTED_TARGET liblzf)
    include(FindPackageHandleStandardArgs)
    find_package_handle_standard_args(liblzf REQUIRED_VARS liblzf_FOUND)
    if(NOT TARGET liblzf::liblzf)
      add_library(liblzf::liblzf ALIAS PkgConfig::liblzf)
     endif()
  '';
in
stdenv.mkDerivation (finalAttrs: {
  pname = "open3d";
  version = "0.19.0";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "isl-org";
    repo = "Open3D";
    tag = "v0.19.0";
    hash = "sha256-jWjtfDcjDBOQHH4s2e1P8ye19JlucYIZPi0pgvOsdcA=";
  };

  patches =
    let
      condaRecipeRev = "e8a6c47d141f605d0f0773a35337f58bb81790fa";
      fetchCondaRecipePatch =
        let
          baseUrl = "https://raw.githubusercontent.com/conda-forge/open3d-feedstock";
        in
        { name, hash }:
        fetchpatch2 {
          inherit hash;
          url = "${baseUrl}/${condaRecipeRev}/recipe/${name}.patch";
        };
    in
    [
      ./find_tinygltf.patch
      ./qhull-link-qhullstatic_r.patch
      (replaceVars ./fix-uvatlas-sources.patch {
        inherit directxHeaders directxMath uvatlas;
      })
      (replaceVars ./use-system-poissonrecon.patch {
        inherit poissonReconInclude;
      })
      (fetchCondaRecipePatch {
        name = "fix-unzip";
        hash = "sha256-1oBzWpusl7NkbhLKBpC8gaROEG6+0kgGZKEPm5rVbk4=";
      })
      (fetchCondaRecipePatch {
        name = "fix-error";
        hash = "sha256-hYB64FzfdLhVUSuFj4Uad/Q9aSdOqDFqsifKGViE8W0=";
      })
      (fetchCondaRecipePatch {
        name = "7249";
        hash = "sha256-5ApyjFMAFk5wEQmKHz4A86khFKd3lf0tEFSVDl+h5wc=";
      })
      (fetchCondaRecipePatch {
        name = "fix-requirements-txt";
        hash = "sha256-shyko5XKFppwSx8Aj0fEAcAuWp1YwphkDFm7du2Z0EU=";
      })
      (fetchCondaRecipePatch {
        name = "fix-missing-memory-include";
        hash = "sha256-eEbNFDUYw/5tjHPUqkI94gnafROmtXrsrhlwbt6hiso=";
      })
      (fetchCondaRecipePatch {
        name = "fix-gcc15-missing-cstdint";
        hash = "sha256-S5bRzq2U97HSQSCNG/UadcM4SPgig370tJ9yrqUHWAQ=";
      })
    ];

  nativeBuildInputs = [
    cmake
    git
    ninja
    pkg-config
  ]
  ++ lib.optionals pythonSupport (
    with pythonPackages;
    [
      pip
      pybind11-stubgen
      setuptools
      wheel
    ]
  )
  ++ lib.optional (stdenv.hostPlatform == stdenv.buildPlatform) pythonPackages.pythonImportsCheckHook
  ++ lib.optional withCuda cudaPackages.cuda_nvcc;

  buildInputs = [
    assimp
    cppzmq
    curl.dev
    eigen
    embree
    fmt
    glew
    glfw
    jsoncpp
    libjpeg
    liblzf.dev
    libpng
    libtiff
    libusb1
    minizip
    msgpack-cxx
    nanoflann
    openblas32
    openssl
    qhull
    stdgpu
    tbb
    tinygltf
    tinyobjloader
    vtk
    zeromq
    zlib
  ]
  ++ lib.optional realsenseSupport librealsense
  ++ lib.optional finalAttrs.finalPackage.doCheck gtest
  ++ lib.optional pythonSupport pythonPackages.pybind11
  ++ lib.optionals withCuda [
    cudaPackages.cccl
    cudaPackages.cuda_cudart
    cudaPackages.libcublas.static
    cudaPackages.libcusolver.static
    cudaPackages.libcusparse.static
    cudaPackages.libnpp.static
    cudaToolkitRoot
    cutlass133
  ];

  propagatedBuildInputs = [
    eigen
    fmt
  ]
  ++ lib.optionals pythonSupport (
    with pythonPackages;
    [
      dash
      numpy
      werkzeug
      flask
      nbformat
      configargparse
    ]
  );

  nativeCheckInputs = [
    gtest
  ]
  ++ lib.optional pythonSupport pythonPackages.pytestCheckHook;

  checkInputs = lib.optionals pythonSupport (
    with pythonPackages;
    [
      certifi
      oauthlib
      pytest
      pytest-randomly
      python
      scipy
      tensorboard
    ]
  );

  preConfigure =
    let
      cmakeBuildType = if debug then "RelWithDebInfo" else "Release";
    in
    ''
      # qt6 setup hook resets this some godforsaken reason
      # https://discourse.nixos.org/t/qt-resetting-cmake-build-type/33468/3
      cmakeBuildType=${cmakeBuildType}
    '';

  checkPhase = ''
    runHook preCheck

    ./bin/tests

    runHook postCheck
  '';

  postInstall = lib.optionalString pythonSupport ''
    python -m pip install ./lib/python_package/pip_package/*.whl --no-index --no-warn-script-location --prefix="$out" --no-cache
  '';

  cmakeFlags =
    let
      inherit (lib)
        cmakeBool
        cmakeFeature
        # cmakeOptionType
        ;
    in
    [
      (cmakeBool "BUILD_COMMON_CUDA_ARCHS" false)
      (cmakeBool "BUILD_CUDA_MODULE" true)
      (cmakeBool "BUILD_EXAMPLES" false)
      (cmakeBool "BUILD_GUI" false)
      (cmakeBool "BUILD_ISPC_MODULE" false)
      (cmakeBool "BUILD_JUPYTER_EXTENSION" false)
      (cmakeBool "BUILD_LIBREALSENSE" realsenseSupport)
      (cmakeBool "BUILD_PYTHON_MODULE" pythonSupport)
      (cmakeBool "BUILD_PYTORCH_OPS" false)
      (cmakeBool "BUILD_SHARED_LIBS" true)
      (cmakeBool "BUILD_TENSORFLOW_OPS" false)
      (cmakeBool "BUILD_UNIT_TESTS" finalAttrs.finalPackage.doCheck)
      (cmakeBool "BUILD_WEBRTC" false)
      (cmakeBool "BUNDLE_OPEN3D_ML" false)
      (cmakeBool "DEVELOPER_BUILD" false)
      (cmakeBool "USE_SYSTEM_ASSIMP" true)
      (cmakeBool "USE_SYSTEM_CURL" true)
      (cmakeBool "USE_SYSTEM_CUTLASS" true)
      (cmakeBool "USE_SYSTEM_EIGEN3" true)
      (cmakeBool "USE_SYSTEM_EMBREE" true)
      (cmakeBool "USE_SYSTEM_FMT" true)
      (cmakeBool "USE_SYSTEM_GLEW" true)
      (cmakeBool "USE_SYSTEM_GLFW" true)
      (cmakeBool "USE_SYSTEM_GOOGLETEST" true)
      (cmakeBool "USE_SYSTEM_IMGUI" true)
      (cmakeBool "USE_SYSTEM_JPEG" true)
      (cmakeBool "USE_SYSTEM_JSONCPP" true)
      (cmakeBool "USE_SYSTEM_LIBLZF" true)
      (cmakeBool "USE_SYSTEM_LIBREALSENSE" true)
      (cmakeBool "USE_SYSTEM_MSGPACK" true)
      (cmakeBool "USE_SYSTEM_NANOFLANN" true)
      (cmakeBool "USE_SYSTEM_OPENSSL" true)
      (cmakeBool "USE_SYSTEM_PNG" true)
      (cmakeBool "USE_SYSTEM_PYBIND11" true)
      (cmakeBool "USE_SYSTEM_QHULLCPP" true)
      (cmakeBool "USE_SYSTEM_STDGPU" true)
      (cmakeBool "USE_SYSTEM_TBB" true)
      (cmakeBool "USE_SYSTEM_TINYGLTF" true)
      (cmakeBool "USE_SYSTEM_TINYOBJLOADER" true)
      (cmakeBool "USE_SYSTEM_VTK" true)
      (cmakeBool "USE_SYSTEM_ZEROMQ" true)
      (cmakeBool "WITH_IPP" false)

      (cmakeFeature "CMAKE_MODULE_PATH" "${cmakeFindLibLzf}/cmake")

      # BLAS
      (cmakeBool "USE_BLAS" true)
      (cmakeBool "USE_SYSTEM_BLAS" true)
      (cmakeFeature "BLA_VENDOR" "OpenBLAS")
      (cmakeFeature "BLA_SIZEOF_INTEGER" "4")
    ];

  installTargets = [
    "install"
  ]
  ++ lib.optional pythonSupport "pip-package";

  disabledTestPaths =
    let
      baseDir = "lib/python_package";
    in
    [
      # skip benchmarks
      "${baseDir}/benchmarks/*"

      # requires networking
      "${baseDir}/test/data/test_data.py"
      "${baseDir}/test/test_octree.py::test_octree_visualize"
      "${baseDir}/test/test_octree.py::test_octree_voxel_grid_convert"
      "${baseDir}/test/test_octree.py::test_locate_leaf_node"
      "${baseDir}/test/io/test_pathlib.py::test_pathlib_support"
      "${baseDir}/test/t/io/test_noise.py::test_apply_depth_noise_model"
      "${baseDir}/test/test_color_map_optimization.py::test_color_map"

      # requires torch even when -DBUILD_PYTORCH_OPS=OFF
      "${baseDir}/test/ml_ops/test_ragged_tensor.py"

      # The test matrix is singular. OpenBLAS GETRF reports a zero pivot for
      # Float32, while this test assumes the factorization succeeds.
      "${baseDir}/test/core/test_linalg.py::test_lu[dtype2-device0]"
    ];

  doCheck = true;

  dontWrapQtApps = true; # gui uses glfw/filament, not qt. But (vtk?) brings in qt

  # reset by qt? set in preConfigure.
  cmakeBuildType = if debug then "Debug" else "RelWithDebInfo";

  dontStrip = debug;
  separateDebugInfo = !debug;

  pythonImportsCheck = [
    "open3d"
  ];

  env = {
    CUDAToolkit_ROOT = "${cudaToolkitRoot}";
    GTEST_FILTER = "-${
      builtins.concatStringsSep ":" (
        [
          # all of the following are disabled because require online fixtures
          "ControlGrid/ControlGridPermuteDevices.*"
          "Dataset.*"
          "Downloader.DownloadAndVerify"
          "Extract.ExtractFromZIP"
          "Feature/FeaturePermuteDevices.ComputeFPFHFeature/0"
          "Feature/FeaturePermuteDevices.CorrespondencesFromFeatures/0"
          "Feature/FeaturePermuteDevices.SelectByIndex/0"
          "Octree.ConvertToJsonValue"
          "Octree.FragmentPLYCheckClone"
          "Octree.FragmentPLYLocate"
          "Octree.Visualization"
          "OctreeIO.JsonFileIOFragment"
          "PointCloud.ClusterDBSCAN"
          "PointCloud.CreateFromDepthImage"
          "PointCloud.CreateFromRGBDImage"
          "PointCloud.DetectPlanarPatches"
          "PointCloud.HiddenPointRemoval"
          "PointCloud.SegmentPlane"
          "PointCloud.SegmentPlaneDeterministic"
          "PointCloud/PointCloudPermuteDevices.ClusterDBSCAN/0"
          "PointCloud/PointCloudPermuteDevices.HiddenPointRemoval/0"
          "PointCloud/PointCloudPermuteDevices.RemoveStatisticalOutliers/0"
          "PointCloud/PointCloudPermuteDevices.SegmentPlane/0"
          "RGBDImage.CreateFromColorAndDepth"
          "RGBDImage.CreateFromRedwoodFormat"
          "RGBDImage.CreateFromSUNFormat"
          "RGBDImage.CreateFromTUMFormat"
          "Registration/RegistrationPermuteDevices.EvaluateRegistration/0"
          "Registration/RegistrationPermuteDevices.GetInformationMatrixFromPointCloud/0"
          "Registration/RegistrationPermuteDevices.ICPColored/0"
          "Registration/RegistrationPermuteDevices.ICPDoppler/0"
          "Registration/RegistrationPermuteDevices.ICPPointToPlane/0"
          "Registration/RegistrationPermuteDevices.ICPPointToPoint/0"
          "TPointCloudIO.ReadPointCloudFromPLY*"
          "TPointCloudIO.ReadPointCloudFromPTS1"
          "TPointCloudIO.ReadWritePTS"
          "TPointCloudIO.ReadWritePointCloudAsNPZ"
          "TPointCloudIO.ReadWritePointCloudAsPCD"
          "TriangleMeshIO.CreateMeshFromFile"
          "TriangleMeshIO.ReadWriteTriangleMeshPLY"
          "TriangleMeshIO.TriangleMeshLegecyCompatibility"
          "UniformTSDFVolume.RealData"
          "VoxelBlockGrid/VoxelBlockGridPermuteDevices.*"
        ]
        ++ lib.optionals withCuda [
          # requires CUDA device
          "CUDAUtils.ScopedStream*"
          "FixedRadiusIndex.*"
          "KnnIndex.*"
          "ParallelFor.LambdaCUDA"
        ]
      )
    }";
  };

  passthru.tests = {
    pkg-config = testers.hasPkgConfigModules { package = finalAttrs.finalPackage; };
    cmake-config = testers.hasCmakeConfigModules {
      package = finalAttrs.finalPackage;
      moduleNames = [ "Open3D" ];
    };
  };

  meta = {
    description = "Open3D 3D data processing library built from source";
    homepage = "https://www.open3d.org/";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ tetov ];
    platforms = lib.platforms.linux;
    pkgConfigModules = [ "Open3D" ];
  };
})
