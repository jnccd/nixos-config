{ config, lib, pkgs, ... }: {
  options.dobikoConf.nonEssentialGuiPkgs.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enables nonEssentialGuiPkgs";
  };

  config = {
    environment.systemPackages = with pkgs;
      [
        # Browser
        firefox
        (vivaldi.overrideAttrs
          (oldAttrs: { vivaldi-ffmpeg-codecs = vivaldi-ffmpeg-codecs; }))
        vivaldi-ffmpeg-codecs

        # Multimedia
        vlc
      ] ++ (if config.dobikoConf.nonEssentialGuiPkgs.enabled then [
        # Multimedia
        gimp
        inkscape-with-extensions
        kdePackages.kdenlive
        blender
        yt-dlp

        # Tools
        pgadmin4-desktopmode
        kdePackages.filelight
        kdePackages.kcalc

        # Productivity
        libreoffice-qt6-fresh
        thunderbird
        anki

        plemoljp-nf # Neovim fonts
      ] else
        [ ]);
  };
}
