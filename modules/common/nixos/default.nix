{ config, lib, pkgs, globalArgs, ... }: {
  imports = [
    ./aliases.nix
    ./misc.nix
    ./nix.nix
    ./packages.nix
    ./podman.nix
    ./postgres.nix
    ./programs.nix
    ./sops-nix.nix
    ./users.nix

  ];
}
