{ pkgs, homeStateVersion, username, ... }:
{
  # --- Packages ---

  home.packages = with pkgs; [
    libsForQt5.filelight
    kdePackages.kate
    gparted

    gimp
    thunderbird
    anki

    (vivaldi.overrideAttrs
    (oldAttrs: {
      dontWrapQtApps = false;
      dontPatchELF = true;
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [pkgs.kdePackages.wrapQtAppsHook];
    }))
    vivaldi-ffmpeg-codecs
  ];

  # --- Programs ---

  programs.firefox.enable = true;

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

  # --- Dotfiles ---

  home.file."/.config" = {
    source = config.lib.file.mkOutOfStoreSymlink ../../dotfiles/.config;
    force = true;
    recursive = true;
  };
  home.file."/.local" = {
    source = config.lib.file.mkOutOfStoreSymlink ../../dotfiles/.local;
    force = true;
    recursive = true;
  };
  home.file."/.background-image" = {
    source = config.lib.file.mkOutOfStoreSymlink ../../dotfiles/.background-image;
    force = true;
  };
}