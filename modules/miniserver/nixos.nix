{ config, pkgs, stateVersion, username, ... }:
{
  imports = [
    ../../modules/miniserver/private-module/nixos.nix
  ];
}