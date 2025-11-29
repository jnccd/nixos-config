{ config, lib, pkgs, inputs, ... }: {
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

      inputs.kwin-effects-forceblur.packages.${system}.default # Wayland
      inputs.kwin-effects-forceblur.packages.${system}.x11

    ];
  };
}
