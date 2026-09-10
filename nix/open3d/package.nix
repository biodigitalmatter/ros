{
  lib,
  stdenv,

  callPackage,
  fetchFromGitHub,
  fetchpatch2,
  replaceVars,
  runCommand,
  writeTextDir,

  debug ? false,
  realsenseSupport ? true,

  assimp,
  cmake,
  cppzmq,
  curl,
  eigen,
  embree,
  fmt,
  git,
  glew,
  glfw,
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
  qhull,
  tbb,
  tinyobjloader,
  vtk,
  zeromq,
  zlib,
}:

let
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
stdenv.mkDerivation (_finalAttrs: {
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
  ];

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
    openblas
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
  ++ lib.optional realsenseSupport librealsense;

  preConfigure =
    let
      cmakeBuildType = if debug then "RelWithDebInfo" else "Release";
    in
    ''
      cmakeFlagsArray+=("-DCMAKE_MODULE_PATH=${cmakeFindLibLzf}/cmake")
      # qt6 setup hook resets this some godforsaken reason
      # https://discourse.nixos.org/t/qt-resetting-cmake-build-type/33468/3
      cmakeBuildType=${cmakeBuildType}
    '';

  cmakeFlags =
    let
      inherit (lib)
        cmakeBool
        # cmakeFeature
        # cmakeOptionType
        ;
    in
    [
      (cmakeBool "BUILD_COMMON_CUDA_ARCHS" false)
      (cmakeBool "BUILD_CUDA_MODULE" false)
      (cmakeBool "BUILD_EXAMPLES" false)
      (cmakeBool "BUILD_GUI" false)
      (cmakeBool "BUILD_ISPC_MODULE" false)
      (cmakeBool "BUILD_JUPYTER_EXTENSION" false)
      (cmakeBool "BUILD_LIBREALSENSE" realsenseSupport)
      (cmakeBool "BUILD_PYTHON_MODULE" false)
      (cmakeBool "BUILD_PYTORCH_OPS" false)
      (cmakeBool "BUILD_SHARED_LIBS" true)
      (cmakeBool "BUILD_TENSORFLOW_OPS" false)
      (cmakeBool "BUILD_TESTS" false)
      (cmakeBool "BUILD_UNIT_TESTS" false)
      (cmakeBool "BUILD_WEBRTC" false)
      (cmakeBool "BUNDLE_OPEN3D_ML" false)
      (cmakeBool "DEVELOPER_BUILD" false)
      (cmakeBool "USE_BLAS" true)
      (cmakeBool "USE_SYSTEM_ASSIMP" true)
      (cmakeBool "USE_SYSTEM_BLAS" true)
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
    ];

  dontWrapQtApps = true; # gui uses glfw/filament, not qt. But something brings in qt

  # reset by qt? set in preConfigure.
  cmakeBuildType = if debug then "Debug" else "RelWithDebInfo";

  dontStrip = debug;
  separateDebugInfo = !debug;

  meta = {
    description = "Open3D 3D data processing library built from source";
    homepage = "https://www.open3d.org/";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ tetov ];
    platforms = lib.platforms.linux;
  };
})
