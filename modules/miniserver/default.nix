{ config, lib, pkgs, globalArgs, ... }: {
  imports = [
    ./private-module
    ./test-service.nix

  ];
}
