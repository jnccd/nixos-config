{ config, lib, pkgs, globalArgs, ... }: {
  imports = [
    ./misc.nix
    ./nix.nix
    ./packages.nix
    ./postgres.nix
    ./programs.nix
    ./users.nix

  ];
}
