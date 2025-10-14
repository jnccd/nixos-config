{ config, lib, pkgs, ... }: {
  options.dobikoConf.kde.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable KDE";
  };

  config = lib.mkIf config.dobikoConf.kde.enabled {
    services.xserver.enable = true;
    services.desktopManager.plasma6.enable = true;

    environment.systemPackages = with pkgs; [
      plasma-panel-colorizer
      kdePackages.plasma-browser-integration

    ];

    environment.sessionVariables.NIXOS_OZONE_WL = "1";
  };
}
