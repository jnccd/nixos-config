{ pkgs, lib }:
pkgs.stdenv.mkDerivation {
  pname = "crossgrub";
  version = "1.0.0";
  src = pkgs.fetchFromGitHub {
    owner = "jnccd";
    repo = "crossgrub";
    rev = "deef3cc1b920432d11c43555ee43b3f156df27d5";
    hash = "sha256-jEXmCH6WPlOo8DUT7OR69KLhuyIIosgoyLAYRpjYiMI=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/
    cp ./assets/*.png ./theme.txt ./*.pf2 $out/

    runHook postInstall
  '';

  passthru.updateScript = pkgs.nix-update-script { };

  meta = with pkgs.lib; {
    description = "A CrossCode-styled GRUB theme";
    license = lib.licenses.mit;
    platforms = platforms.linux;
  };
}
