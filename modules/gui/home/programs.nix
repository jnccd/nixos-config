{ config, pkgs, globalArgs, ... }:
{
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      jnoortheen.nix-ide
      arrterian.nix-env-selector
      #shipitsmarter.sops-edit

      streetsidesoftware.code-spell-checker

      ms-dotnettools.csdevkit
      ms-python.python

      ms-vscode-remote.remote-ssh
    ];
  };
}