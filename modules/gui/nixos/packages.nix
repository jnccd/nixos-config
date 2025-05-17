{ config, lib, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    firefox
    vlc
    loupe

    alsa-utils
    sddm-astronaut
    plemoljp-nf # Neovim fonts
  ];
}
