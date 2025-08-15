{ config, lib, pkgs, ... }: {
  options.dobikoConf.xfce.enabled = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable XFCE";
  };

  config = lib.mkIf config.dobikoConf.xfce.enabled {
    services.xserver = {
      enable = true;
      desktopManager = {
        xterm.enable = false;
        xfce.enable = true;
      };
    };

    environment.systemPackages = (with pkgs.xfce; [
      xfce4-panel-profiles
      xfce4-whiskermenu-plugin

    ]) ++ (with pkgs; [
      qogir-theme
      qogir-icon-theme

    ]);
  };
}
