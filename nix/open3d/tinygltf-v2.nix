{
  fetchFromGitHub,
  tinygltf,

}:
let
  # open3D uses 2.4
  version = "2.9.7";
in
tinygltf.overrideAttrs (_old: {
  inherit version;

  src = fetchFromGitHub {
    owner = "syoyo";
    repo = "tinygltf";
    tag = "v${version}";
    hash = "sha256-tG9hrR2rsfgS8zCBNdcplig2vyiIcNspSVKop03Zx9A=";
  };
})
