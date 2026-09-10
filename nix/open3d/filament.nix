{
  fetchurl,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "open3d-filament";
  version = "1.9.19";

  src = fetchurl {
    url = "https://github.com/isl-org/open3d_downloads/releases/download/filament/filament-v1.9.19-linux-20.04.tgz";
    hash = "sha256-x1b9dvXGpAylVPjDzKQkNUoqIupvzjyOqJPUxKo5UUw=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
        cp -r . $out
        mv $out/bin/matc $out/bin/matc.bin
        cat > $out/bin/matc <<EOF
    #!${stdenv.shell}
    exec ${stdenv.cc.bintools.dynamicLinker} $out/bin/matc.bin "\$@"
    EOF
        chmod +x $out/bin/matc
  '';
}
