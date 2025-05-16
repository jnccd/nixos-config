{ config, lib, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    firefox
    alsa-utils
    sddm-astronaut
    plemoljp-nf # Neovim fonts
  ];
}
