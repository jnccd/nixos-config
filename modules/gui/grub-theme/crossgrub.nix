{ pkgs, lib }:
pkgs.stdenv.mkDerivation {
  pname = "crossgrub";
  version = "1.0.0";
  src = pkgs.fetchFromGitHub {
    owner = "krypciak";
    repo = "crossgrub";
    tag = "1.0.0";
    hash = "sha256-TDgi9e2/aHngdzFCkx0ykZedP3v4IFKiYJGTcWUo+rk=";
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
