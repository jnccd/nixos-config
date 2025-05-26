{ config, lib, pkgs, ... }: {
  environment.systemPackages = (with pkgs; [
    # Base
    plasma-panel-colorizer
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
        ++ [ pkgs.kdePackages.wrapQtAppsHook ];
    }))
    vivaldi-ffmpeg-codecs

    # Multimedia
    vlc
    gimp

    # Tools
    gparted
    alsa-utils
    pgadmin4-desktopmode

    # Productivity
    thunderbird
    anki

    plemoljp-nf # Neovim fonts
  ]) ++ (with pkgs.kdePackages; [
    qtmultimedia # For sddm theme
    filelight
    kate
  ]);
}
