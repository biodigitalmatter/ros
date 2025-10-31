{
  lib,
  buildRosPackage,
  ament-cmake,
  ros-environment,
  fetchurl,
  writeTextFile,
  backward-cpp,
  bzip2,
  catch2,
  cpr,
  curl,
  fp16,
  ghc_filesystem,
  libarchive,
  libnop,
  libusb1,
  nlohmann_json,
  opencv,
  pkg-config,
  python3,
  spdlog,
  xlink,
  xz,
  zlib,
}:
buildRosPackage {
  pname = "ros-jazzy-depthai";
  version = "2.30.0-r1";

  src = fetchurl {
    url = "https://github.com/luxonis/depthai-core-release/archive/release/jazzy/depthai/2.30.0-1.tar.gz";
    name = "2.30.0-1.tar.gz";
    sha256 = "a764abdff64b246db0940663a7096a319e2a4010a2c2981f4ca5c7842412ef09";
  };
  buildType = "ament_cmake";

  buildInputs = [
    ament-cmake
    ros-environment
    backward-cpp
    bzip2.dev
    catch2
    cpr
    curl
    ghc_filesystem
    libarchive
    libusb1
    nlohmann_json
    opencv
    opencv.cxxdev
    spdlog
    xlink
    xz
    zlib
    python3
  ];

  nativeBuildInputs = [
    pkg-config
    ament-cmake
  ];

  propagatedBuildInputs = [
    libnop
    nlohmann_json
    xlink
  ];

  patches = [ ./cmake_deps.patch ];

  cmakeFlags =
    let
      inherit (lib) cmakeBool cmakeFeature concatStringsSep;

      luxonisArtifactoryUrl = "https://artifacts.luxonis.com/artifactory";

      # from cmake/Depthai/DepthaiDeviceSideConfig.cmake and cmake/DepthaiDownloader.cmake
      firmware =
        let
          name = "depthai-device-fwp";
          rev = "a62b2ccb0bc493c2fb41694cb81c08887be24c52";
        in
        builtins.fetchurl {
          # name = "${name}.tar.xz";
          url = "${luxonisArtifactoryUrl}/luxonis-myriad-snapshot-local/depthai-device-side/${rev}/${name}-${rev}.tar.xz";

          sha256 = "sha256-njwp9WIq0OyEIsHx4hoHhbRAr+W3tl/PnmQ77OBgbZc=";
        };

      # from cmake/DepthaiBootloaderDownloader.cmake and cmake/Depthai/DepthaiBootloaderConfig.cmake
      bootloader =
        let
          name = "depthai-bootloader-fwp";
          rev = "0.0.28";
        in
        builtins.fetchurl {
          # name = "${name}.tar.xz";
          url = "${luxonisArtifactoryUrl}/luxonis-myriad-release-local/depthai-bootloader/${rev}/${name}-${rev}.tar.xz";
          sha256 = "sha256-5xQ7vj0BLt2dgZQKC+Ug6BVkcIt7TsebBx1wF1i7gow=";
        };
    in
    [
      (cmakeBool "HUNTER_ENABLED" false)
      (cmakeBool "DEPTHAI_ENABLE_BACKWARD" false)
      (cmakeFeature "FP16_DIR" (
        toString (writeTextFile {
          name = "FP16Config";
          text = ''
            if(NOT TARGET FP16::fp16)
              add_library(FP16::fp16 INTERFACE IMPORTED)
              target_include_directories(FP16::fp16 INTERFACE "${fp16}/include")
            endif()
          '';
          destination = "/FP16Config.cmake";
        })
      ))
      (cmakeFeature "libnop_DIR" (
        toString (writeTextFile {
          name = "libnop-config";
          text = ''
            add_library(libnop INTERFACE IMPORTED)
            target_include_directories(libnop INTERFACE "${libnop}/include")
          '';
          destination = "/libnopConfig.cmake";
        })
      ))
      (cmakeBool "DEPTHAI_ENABLE_CURL" false) # only used for telemetry and zoo
      (cmakeBool "CMAKE_SKIP_INSTALL_ALL_DEPENDENCY" true)
      (cmakeFeature "CMAKE_INSTALL_PREFIX" "${placeholder "out"}")
      (cmakeFeature "CMAKE_INSTALL_INCLUDEDIR" "include")
      (cmakeFeature "CMAKE_INSTALL_LIBDIR" "lib")
      (cmakeBool "BUILD_SHARED_LIBS" true)
      (cmakeBool "CMAKE_FIND_NO_INSTALL_PREFIX" true)
      (cmakeFeature "DEPTHAI_BOOTLOADER_FWP" "${bootloader}")
      (cmakeFeature "DEPTHAI_DEVICE_FWP" "${firmware}")
      (cmakeFeature "CMAKE_MODULE_PATH" (
        concatStringsSep ";" [
          "${xlink}/lib/cmake"
          "${libnop}/lib/cmake"
        ]
      ))
    ];

  meta = {
    description = "DepthAI core is a C++ library which comes with firmware and an API to interact with OAK Platform";
    license = with lib.licenses; [ mit ];
  };
}
