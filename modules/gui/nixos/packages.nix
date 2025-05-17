{ config, lib, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    firefox
    vlc

    plasma-panel-colorizer
    sddm-astronaut

    alsa-utils

    plemoljp-nf # Neovim fonts
  ];
}
