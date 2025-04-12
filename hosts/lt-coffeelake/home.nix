# home-manager switch --flake .
{ config, pkgs, ... }: {
  nixpkgs.config = {
    allowUnfree = true;
  };

  home = {
    username = "dobiko";
    homeDirectory = "/home/dobiko";
    stateVersion = "24.11";

    packages = with pkgs; [
      libsForQt5.filelight
      kdePackages.kate
      gparted

      minecraft
      gimp

      (vivaldi.overrideAttrs
      (oldAttrs: {
        dontWrapQtApps = false;
        dontPatchELF = true;
        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [pkgs.kdePackages.wrapQtAppsHook];
      }))
      vivaldi-ffmpeg-codecs
    ];
  };
  
  programs.firefox.enable = true;

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
      arrterian.nix-env-selector

      ms-dotnettools.csdevkit
      ms-python.python

      ms-vscode-remote.remote-ssh
    ];
  };
}