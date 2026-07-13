{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.dobikoConf.wine.enabled = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enables wine packages";
  };

  config = lib.mkIf config.dobikoConf.wine.enabled {
    environment.systemPackages = with pkgs; [
      wineWow64Packages.waylandFull
      wineWow64Packages.fonts
      winetricks
    ];
  };
}
