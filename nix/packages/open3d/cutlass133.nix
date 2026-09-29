{
  packageSources,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "cutlass";
  version = "1.3.3";

  src = packageSources.cutlass133;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/include
    cp -r cutlass $out/include/
  '';
}
