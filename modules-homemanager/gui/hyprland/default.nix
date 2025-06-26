{ config, lib, pkgs, globalArgs, ... }: {
  options.hyprland.enabled = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "hyper land AWAU!";
  };

  imports = lib.optionals config.hyprland.enabled [
    ./hyprland
    ./swaync
    ./waybar
    ./wofi
    ./alacritty.nix
  ];
}
