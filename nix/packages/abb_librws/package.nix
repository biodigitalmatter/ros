{
  packageSources,
  lib,
  stdenv,
  cmake,
  poco,
}:

stdenv.mkDerivation {
  pname = "abb_librws";
  version = "0-unstable-2023-02-22";

  src = packageSources.abb_librws;

  nativeBuildInputs = [
    cmake
  ];

  propagatedBuildInputs = [
    poco
  ];

  meta = {
    description = "C++ library for interfacing with ABB robot controllers through the Robot Web Services (RWS) interface";
    homepage = "https://github.com/ros-industrial/abb_librws";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [
      tetov
    ];
  };
}
