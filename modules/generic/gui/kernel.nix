{ config, lib, pkgs, globalArgs, ... }: {
  boot.kernelPackages = pkgs.linuxPackages_zen;
}
