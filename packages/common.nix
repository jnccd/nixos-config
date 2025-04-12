{ config, pkgs, stateVersion, hostname, ... }:
{
  commonPackages = with pkgs; [
    nushell
  ]
}