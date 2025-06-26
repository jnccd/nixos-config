{ config, lib, pkgs, globalArgs, ... }: {
  options.hyprland.enabled = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "hyper land AWAU!";
  };

  config = lib.mkIf config.hyprland.enabled {
    imports = [ ./hyprland ./swaync ./waybar ./wofi ./alacritty.nix ];
  };
}
