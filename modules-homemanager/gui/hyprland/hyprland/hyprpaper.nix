{ config, lib, pkgs, globalArgs, ... }: {
  # Wallpaper is configured in ../stylix.nix
  services.hyprpaper = { enable = true; };
}
