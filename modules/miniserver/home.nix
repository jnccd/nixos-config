{ config, lib, pkgs, ... }:
{
  imports = [
    ./private-module/home.nix
  ];
}