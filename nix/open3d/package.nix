{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch2,
  runCommand,

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
  imgui,
  jsoncpp,
  libjpeg,
  liblzf,
  libpng,
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

  tinygltfSource = fetchFromGitHub {
    owner = "syoyo";
    repo = "tinygltf";
    rev = "72f4a55edd54742bca1a71ade8ac70afca1d3f07";
    hash = "sha256-vlVhDH2/vOKn+iQWhVUFIEe5uNDeQ51i5ZTx7uCSeLY=";
  };

  tinygltfCompat = runCommand "open3d-tinygltf" { } ''
    mkdir -p $out/include $out/lib/cmake/TinyGLTF
    cp -r ${tinygltfSource}/* $out/include/
    cat > $out/lib/cmake/TinyGLTF/TinyGLTFConfig.cmake <<EOF
    set(TinyGLTF_FOUND TRUE)
    if(NOT TARGET TinyGLTF::TinyGLTF)
      add_library(TinyGLTF::TinyGLTF INTERFACE IMPORTED)
      set_target_properties(TinyGLTF::TinyGLTF PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "''${CMAKE_CURRENT_LIST_DIR}/../../include"
        INTERFACE_COMPILE_DEFINITIONS "TINYGLTF_IMPLEMENTATION;STB_IMAGE_IMPLEMENTATION;STB_IMAGE_WRITE_IMPLEMENTATION"
      )
    endif()
    EOF
  '';
  uvatlas = fetchFromGitHub {
    owner = "microsoft";
    repo = "UVAtlas";
    tag = "may2022";
    hash = "sha256-BP2hkEexo1E0sL43pYKsPhCsP+t7ffupVad06ZctvXs=";
  };
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

  postPatch = ''
    substituteInPlace 3rdparty/uvatlas/uvatlas.cmake \
      --replace-fail 'set(UVATLAS_LIB_DIR ''${INSTALL_DIR}/''${Open3D_INSTALL_LIB_DIR})' 'set(UVATLAS_LIB_DIR ''${CMAKE_INSTALL_PREFIX}/lib)' \
      --replace-fail '<INSTALL_DIR>/''${Open3D_INSTALL_LIB_DIR}/''${CMAKE_STATIC_LIBRARY_PREFIX}UVAtlas''${CMAKE_STATIC_LIBRARY_SUFFIX}' ' ''${CMAKE_INSTALL_PREFIX}/lib/''${CMAKE_STATIC_LIBRARY_PREFIX}UVAtlas''${CMAKE_STATIC_LIBRARY_SUFFIX}' \
      --replace-fail "GIT_REPOSITORY https://github.com/microsoft/DirectX-Headers.git" "SOURCE_DIR ${directxHeaders}" \
      --replace-fail "GIT_TAG v1.606.3" "" \
      --replace-fail "GIT_REPOSITORY https://github.com/microsoft/DirectXMath.git" "SOURCE_DIR ${directxMath}" \
      --replace-fail "GIT_TAG may2022" "" \
      --replace-fail "URL https://github.com/microsoft/UVAtlas/archive/refs/tags/may2022.tar.gz" "URL ${uvatlas}" \
      --replace-fail "URL_HASH SHA256=591516913a0f3c381f1fd01647cb1b8d1eeade575d1c726ae8f5dd9f83b81754" ""

    substituteInPlace 3rdparty/possionrecon/possionrecon.cmake \
      --replace-fail "URL https://github.com/isl-org/Open3D-PoissonRecon/archive/90f3f064e275b275cff445881ecee5a7c495c9e0.tar.gz" "" \
      --replace-fail "URL_HASH SHA256=1310df0c80ff0616b8fcf9b2fb568aa9b2190d0e071b0ead47dba339c146b1d3" "" \
      --replace-fail "SOURCE_DIR \"poisson/src/ext_poisson/PoissonRecon\"" "SOURCE_DIR ${poissonRecon}" \
      --replace-fail 'set(POISSON_INCLUDE_DIRS ''${SOURCE_DIR})' "set(POISSON_INCLUDE_DIRS ${poissonReconInclude}/)"
  '';

  patches = [
    (fetchpatch2 {
      url = "https://raw.githubusercontent.com/conda-forge/open3d-feedstock/main/recipe/fix-unzip.patch";
      hash = "sha256-1oBzWpusl7NkbhLKBpC8gaROEG6+0kgGZKEPm5rVbk4=";
    })
    (fetchpatch2 {
      url = "https://raw.githubusercontent.com/conda-forge/open3d-feedstock/main/recipe/fix-error.patch";
      hash = "sha256-hYB64FzfdLhVUSuFj4Uad/Q9aSdOqDFqsifKGViE8W0=";
    })
    (fetchpatch2 {
      url = "https://raw.githubusercontent.com/conda-forge/open3d-feedstock/main/recipe/fix-find-imgui.patch";
      hash = "sha256-h8JOdb5Uy0qXuthuIfA+4UyTF/oRMWbkXDYNLrli8iE=";
    })
    (fetchpatch2 {
      url = "https://raw.githubusercontent.com/conda-forge/open3d-feedstock/main/recipe/7249.patch";
      hash = "sha256-5ApyjFMAFk5wEQmKHz4A86khFKd3lf0tEFSVDl+h5wc=";
    })
    (fetchpatch2 {
      url = "https://raw.githubusercontent.com/conda-forge/open3d-feedstock/main/recipe/fix-requirements-txt.patch";
      hash = "sha256-shyko5XKFppwSx8Aj0fEAcAuWp1YwphkDFm7du2Z0EU=";
    })
    (fetchpatch2 {
      url = "https://raw.githubusercontent.com/conda-forge/open3d-feedstock/main/recipe/fix-missing-memory-include.patch";
      hash = "sha256-eEbNFDUYw/5tjHPUqkI94gnafROmtXrsrhlwbt6hiso=";
    })
    (fetchpatch2 {
      url = "https://raw.githubusercontent.com/conda-forge/open3d-feedstock/main/recipe/fix-gcc15-missing-cstdint.patch";
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
    imgui
    jsoncpp
    libjpeg
    liblzf.dev
    libpng
    libtiff
    libusb1
    minizip
    # msgpack-c
    msgpack-cxx
    nanoflann
    openblas
    openssl
    qhull
    tbb
    tinygltfCompat
    tinyobjloader
    vtk
    zeromq
    zlib
  ];

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
      (cmakeBool "BUILD_LIBREALSENSE" false)
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
      (cmakeBool "USE_SYSTEM_EIGEN3" true)
      (cmakeBool "USE_SYSTEM_EMBREE" true)
      (cmakeBool "USE_SYSTEM_FMT" true)
      (cmakeBool "USE_SYSTEM_GLEW" true)
      (cmakeBool "USE_SYSTEM_GLFW" true)
      (cmakeBool "USE_SYSTEM_JPEG" true)
      (cmakeBool "USE_SYSTEM_JSONCPP" true)
      (cmakeBool "USE_SYSTEM_LIBLZF" true)
      (cmakeBool "USE_SYSTEM_MSGPACK" true)
      (cmakeBool "USE_SYSTEM_NANOFLANN" true)
      (cmakeBool "USE_SYSTEM_OPENSSL" true)
      (cmakeBool "USE_SYSTEM_PNG" true)
      (cmakeBool "USE_SYSTEM_QHULLCPP" true)
      (cmakeBool "USE_SYSTEM_TBB" true)
      (cmakeBool "USE_SYSTEM_TINYGLTF" true)
      (cmakeBool "USE_SYSTEM_TINYOBJLOADER" true)
      (cmakeBool "USE_SYSTEM_VTK" true)
      (cmakeBool "USE_SYSTEM_ZEROMQ" true)
      (cmakeBool "WITH_IPP" false)
    ];

  dontWrapQtApps = true; # gui uses glfw/filament, not qt. But something brings in qt
  meta = {
    description = "Open3D 3D data processing library built from source";
    homepage = "https://www.open3d.org/";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ tetov ];
    platforms = lib.platforms.linux;
  };
})
