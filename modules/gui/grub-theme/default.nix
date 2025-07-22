{ config, lib, pkgs, globalArgs, ... }:
let
  crossgrub-src = pkgs.fetchFromGitHub {
    owner = "krypciak";
    repo = "crossgrub";
    tag = "1.0.0";
    hash = "sha256-TDgi9e2/aHngdzFCkx0ykZedP3v4IFKiYJGTcWUo+rk=";
  };
in {
  boot.loader.grub.theme = "${import ./crossgrub.nix { inherit pkgs lib; }}";
  boot.loader.grub.splashImage = "${crossgrub-src}/assets/background.png";
}
