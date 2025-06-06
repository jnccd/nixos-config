{ config, lib, pkgs, globalArgs, ... }: {
  environment.systemPackages = [
    (pkgs.stdenv.mkDerivation {
      name = "custom-taskbar-icons";
      src = ./windowsy-breeze-dark;
      installPhase = ''
        mkdir -p $out/share/plasma/desktoptheme/windowsy-breeze-dark/
        cp -r . $out/share/plasma/desktoptheme/windowsy-breeze-dark/
      '';
    })
  ];
}
