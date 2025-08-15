{ config, lib, pkgs, ... }: {
  options.dobikoConf.xcfe.enabled = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable XCFE";
  };

  config = lib.mkIf config.dobikoConf.xcfe.enabled {
    services.xserver = {
      enable = true;
      desktopManager = {
        xterm.enable = false;
        xfce.enable = true;
      };
    };

    environment.systemPackages = with pkgs.xfce; [
      xfce4-panel-profiles
      xfce4-whiskermenu-plugin

    ];
  };
}
