{ config, pkgs, globalArgs, ... }:
{
  imports = [
    ./packages.nix
    ./programs.nix
  ];
}
