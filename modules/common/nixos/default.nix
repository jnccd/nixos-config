{ config, lib, pkgs, globalArgs, ... }:
{
  imports = [
    ./misc.nix
    ./nix.nix
    ./packages.nix
    ./programs.nix
    ./users.nix
  ];
}