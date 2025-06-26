{ config, lib, pkgs, globalArgs, ... }: {
  imports = [
    ./hyprland
    ./swaync
    ./waybar
    ./wofi
    ./alacritty.nix

  ];
}
