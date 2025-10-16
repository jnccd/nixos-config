{ config, lib, pkgs, ... }: {
  options.dobikoConf.niri.enabled = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable Niri";
  };

  config = lib.mkIf config.dobikoConf.niri.enabled {
    programs.niri.enable = true;

    security.polkit.enable = true;
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.swaylock = { };

    environment.systemPackages = with pkgs; [
      alacritty
      fuzzel
      waybar
      swaylock
      mako
      swayidle
    ];
  };
}
