{ config, lib, pkgs, ... }: {
  environment.systemPackages = with pkgs;
    [
      # Base
      plasma-panel-colorizer
      sddm-astronaut

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

      # Coding
      dotnet-sdk
      dotnet-sdk_6
      dotnet-ef

      plemoljp-nf # Neovim fonts
    ] ++ (with kdePackages; [ filelight kate ]);
}
