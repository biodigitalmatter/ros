{
  fetchFromGitHub,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "cutlass";
  version = "1.3.3";

  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "cutlass";
    tag = "v1.3.3";
    hash = "sha256-Geatc0MCGtPDdlb8SXPopsepaREkBysuZgaZYoIkFHg=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/include
    cp -r cutlass $out/include/
  '';
}
