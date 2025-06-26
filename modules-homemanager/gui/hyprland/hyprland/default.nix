{ config, lib, pkgs, globalArgs, ... }: {
  imports =
    [ ./binds.nix ./hypridle.nix ./hyprlock.nix ./hyprpaper.nix ./main.nix ];

  home.packages = with pkgs; [ hello ];
}
