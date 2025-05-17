{ config, pkgs, globalArgs, ... }: {
  home.packages = with pkgs;
    [
      gparted

      gimp
      thunderbird
      anki

      (vivaldi.overrideAttrs (oldAttrs: {
        dontWrapQtApps = false;
        dontPatchELF = true;
        nativeBuildInputs = oldAttrs.nativeBuildInputs
          ++ [ pkgs.kdePackages.wrapQtAppsHook ];
      }))
      vivaldi-ffmpeg-codecs
    ] ++ (with kdePackages; [ filelight kate ]);
}
