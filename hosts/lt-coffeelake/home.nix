# home-manager switch -b backup --flake .
{ config, pkgs, username, homeStateVersion, ... }: {
  nixpkgs.config = {
    allowUnfree = true;
  };

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = homeStateVersion;

    packages = with pkgs; [
      libsForQt5.filelight
      kdePackages.kate
      gparted

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
  # Write dotfiles
  home.file."/.config" = {
    source = ../../dotfiles/.config;
    force = true;
    recursive = true;
  };
  home.file."/.local" = {
    source = ../../dotfiles/.local;
    force = true;
    recursive = true;
  };
  home.file."/.background-image" = {
    source = ../../dotfiles/.background-image;
    force = true;
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

      streetsidesoftware.code-spell-checker

      ms-dotnettools.csdevkit
      ms-python.python

      ms-vscode-remote.remote-ssh
    ];
  };
}