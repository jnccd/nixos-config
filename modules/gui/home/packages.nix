{ config, pkgs, globalArgs, ... }: {
  home.packages = with pkgs; [
    kdePackages.filelight
    kdePackages.kate
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
  ];
}
