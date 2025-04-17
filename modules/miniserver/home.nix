{ config, pkgs, homeStateVersion, username, ... }:
{
  imports = [
    ../../modules/miniserver/private-module/home.nix
  ];
}