{ pkgs, ... }:
{
  systemPackages = with pkgs; [
    home-manager
    htop
    neofetch
    wget
    vim
    nushell
  ];
}