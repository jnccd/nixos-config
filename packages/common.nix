{ config, pkgs, stateVersion, hostname, ... }:
{
  commonPackages = with pkgs; [
    vim
  ]
}