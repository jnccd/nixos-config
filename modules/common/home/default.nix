{ config, pkgs, globalArgs, ... }: {
  imports = [
    ./misc.nix
    ./programs.nix

  ];
}
