{ config, lib, pkgs, globalArgs, ... }: {
  imports = [
    ./packages.nix
    ./programs.nix

    ./misc.nix
    ./nix.nix
    ./users.nix
  ];
}
