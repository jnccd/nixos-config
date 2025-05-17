{ config, lib, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    firefox
    vlc

    alsa-utils
    sddm-astronaut
    plemoljp-nf # Neovim fonts
  ];
}
