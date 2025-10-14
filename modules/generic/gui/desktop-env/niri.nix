{ config, lib, pkgs, ... }: {
  options.dobikoConf.niri.enabled = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable Niri";
  };

  config = lib.mkIf config.dobikoConf.niri.enabled {
    programs.niri.enable = true;

    security.polkit.enable = true; # polkit
    services.gnome.gnome-keyring.enable = true; # secret service
    security.pam.services.swaylock = { };

    programs.waybar.enable = true; # top bar
    environment.systemPackages = with pkgs; [
      alacritty
      fuzzel
      swaylock
      mako
      swayidle
    ];
  };
}
