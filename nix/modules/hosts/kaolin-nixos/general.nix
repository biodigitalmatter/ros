{ ... }:
{
  flake.modules.nixos."hosts/kaolin-nixos" =
    { ... }:
    {
      users.users = {
        root.hashedPassword = "$y$j9T$ih8u6wy4D2cJkcXPeBoVC.$phd7o4jdiI/Xc.VZHgBUN8RUft86Lb/pCTjtSDM85j7";
        tetov.hashedPassword = "$y$j9T$cy5Pub/OwyJ.zg8WIZcGZ.$iJsGik73JJMsHgql5GNmgo1hhSdwdAm6qCl3KnjlVO7";
      };
      system.stateVersion = "25.11";
    };
}
