{ config, lib, pkgs, globalArgs, ... }: {
  options.hyprland.enabled = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "hyper land AWAU!";
  };

  config = lib.mkIf config.hyprland.enabled {
    programs.hyprland.enable = true;

    environment.systemPackages = with pkgs; [
      hyprland
      waybar
      rofi-wayland
      alacritty
      kitty
      xfce.thunar
      swww
      pavucontrol
      brightnessctl
      pamixer
    ];
  };
}
