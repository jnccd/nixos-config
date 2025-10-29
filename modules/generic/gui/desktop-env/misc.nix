{ config, lib, pkgs, ... }: {
  programs.gnupg.agent.pinentryPackage = lib.mkForce pkgs.pinentry-qt;

  environment.sessionVariables.NIXOS_OZONE_WL = "";
}
