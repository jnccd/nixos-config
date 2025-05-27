{ config, lib, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Base
    plasma-panel-colorizer
    kdePackages.qtmultimedia # For sddm theme
    (sddm-astronaut.override {
      embeddedTheme = "purple_leaves";
      themeConfig = { FormPosition = "left"; };
    })

    # Browser
    firefox
    (vivaldi.overrideAttrs (oldAttrs: {
      dontWrapQtApps = false;
      dontPatchELF = true;
      nativeBuildInputs = oldAttrs.nativeBuildInputs
        ++ [ kdePackages.wrapQtAppsHook ];
    }))
    vivaldi-ffmpeg-codecs
    kdePackages.plasma-browser-integration

    # Multimedia
    vlc
    gimp

    # Tools
    gparted
    alsa-utils
    pgadmin4-desktopmode
    kdePackages.filelight
    kdePackages.kate

    # Productivity
    libreoffice-qt6-fresh
    thunderbird
    anki

    plemoljp-nf # Neovim fonts
  ];
}
