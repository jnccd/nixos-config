{ config, lib, pkgs, ... }: {
  programs.gnupg.agent.pinentryPackage = lib.mkForce pkgs.pinentry-qt;
}
