{
  packageSources,

  lib,
  stdenv,

  cmake,
  boost186,
  protobuf,
}:

stdenv.mkDerivation {
  pname = "abb_libegm";
  version = "0-unstable-2023-02-22";

  src = packageSources.abb_libegm;

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    boost186
    protobuf
  ];

  meta = {
    description = "C++ library for interfacing with ABB robot controllers through the Externally Guided Motion (EGM) interface";
    homepage = "https://github.com/ros-industrial/abb_libegm";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ tetov ];
  };
}
