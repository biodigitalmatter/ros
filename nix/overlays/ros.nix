# SPDX-FileCopyrightText: (C) 2026 Anton Tetov Johansson <anton@tetov.se>
# SPDX-License-Identifier: Apache-2.0

toplevelPackages:
# ros scope
final: _prev:
toplevelPackages.lib.packagesFromDirectoryRecursive {
  inherit (final) callPackage;
  directory = ../packages/ros;
}
// {
  # name collision
  # using tl-expected from rcpputils instead
  # tl-expected-nixpkgs = toplevelPackages.tl-expected;
}
