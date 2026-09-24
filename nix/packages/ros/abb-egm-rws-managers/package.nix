{
  lib,
  fetchFromGitHub,
  buildRosPackage,
  abb_libegm,
  abb_librws,
  boost186,
  cmake,
  eigen,
  poco,
  protobuf,
}:
buildRosPackage {
  pname = "ros-jazzy-abb-egm-rws-managers";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "ros-industrial";
    repo = "abb_egm_rws_managers";
    rev = "7e554e53b415df1bbd743392b84a055c499b63d2";
    hash = "sha256-kmi/g3Bj1gMvgWwh7LPuXazx7J3p6gl3Jvs3jRBmxY4=";
  };

  buildType = "cmake";
  buildInputs = [ cmake ];
  propagatedBuildInputs = [
    abb_libegm
    abb_librws
    boost186
    eigen
    poco
    protobuf
  ];

  meta = {
    description = "Provides a C++ library for managing communication with ABB robot controllers, via
    the Robot Web Services (RWS) and the Externally Guided Motion (EGM) interfaces.";
    license = with lib.licenses; [ bsd3 ];
  };
}
