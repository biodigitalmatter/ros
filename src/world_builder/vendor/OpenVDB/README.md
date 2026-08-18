# Vendored OpenVDB cmake files

From openvdb 12.1.0 in [nixpkgs](https://github.com/nixos/nixpkgs) revision `b5aa0fbd538984f6e3d201be0005b4463d8b09f8`.

``` sh
PKG=$(nix eval --inputs-from . --raw nixpkgs#legacyPackages.x86_64-linux.openvdb.dev)
cp $PKG/lib/cmake/OpenVDB/* ./cmake/
```
