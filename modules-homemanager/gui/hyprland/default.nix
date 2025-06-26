{ config, lib, pkgs, globalArgs, ... }: {
  imports = lib.mkOptionals false [
    ./hyprland
    ./swaync
    ./waybar
    ./wofi
    ./alacritty.nix

  ];
}
