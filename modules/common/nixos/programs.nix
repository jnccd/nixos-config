{ config, lib, pkgs, globalArgs, ... }:
{
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}