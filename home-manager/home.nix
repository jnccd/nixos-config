# home-manager switch
{ config, pkgs, ... }: {
  nixpkgs.config = {
    allowUnfree = true;
  };

  home = {
    username = "dobiko";
    homeDirectory = "/home/dobiko";
    stateVersion = "24.11";

    packages = with pkgs; [
      (vivaldi.overrideAttrs
      (oldAttrs: {
        dontWrapQtApps = false;
        dontPatchELF = true;
        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [pkgs.kdePackages.wrapQtAppsHook];
      }))
      vivaldi-ffmpeg-codecs
    ];
  };

  programs.bash = {
    enable = true;
    shellAliases = { 
      rebuild = "sudo nixos-rebuild switch";
    };
  };

  programs.git = {
    enable = true;
    userName  = "jnccd";
    userEmail = "kobidogao@outlook.com";
  };

  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      jnoortheen.nix-ide

      ms-python.python

      ms-vscode-remote.remote-ssh
    ];
  };
}