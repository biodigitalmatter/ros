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
    rev = "ea7d418e7b34aaacc033365d5326b6a6befde3df";
    hash = "sha256-xpcB/DnaFphT3JVwJDbiiYFkzQgk04tB0I5Mh8rsIkE=";
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
