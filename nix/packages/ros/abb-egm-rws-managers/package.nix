{
  packageSources,
  lib,
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

  src = packageSources.abb_egm_rws_managers;

  patches = [
    ./debug-system-info-error.patch
  ];

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
