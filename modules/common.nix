{ config, pkgs, stateVersion, hostname, ... }:
{
  commonPackages = with pkgs; [
    home-manager
    htop
    neofetch
    wget
    vim
  ]
}