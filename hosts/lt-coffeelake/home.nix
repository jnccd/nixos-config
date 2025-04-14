# home-manager switch --flake .
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

  home.file."." = {
    source = ../../dotfiles;
    force = true;
    recursive = true;
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