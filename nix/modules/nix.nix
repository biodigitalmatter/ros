{ lib, ... }:
{
  flake.modules.nixos.nix =
    { ... }:
    {
      nix = {
        settings = {
          auto-optimise-store = true;
          connect-timeout = 10;
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          extra-substituters = [
            "https://binarycache.tetov.se/"
            "https://ros.cachix.org"
          ];
          extra-trusted-public-keys = [
            "binarycache.tetov.se:84dA6GWAIObxcK+7BhlVreVThNAXELdtTX+i2fRipyE="
            "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo="
          ];
          fallback = true;
          trusted-users = [
            "root"
            "@wheel"
          ];
          use-xdg-base-directories = true;
        };
        gc = {
          automatic = lib.mkDefault true;
          dates = lib.mkDefault "weekly";
          persistent = true;
          randomizedDelaySec = "45min";
          options = lib.mkDefault "--delete-older-than 7d";
        };
      };
    };
}
