{ config, lib, pkgs, stateVersion, username, ... }:
{
  imports = [
    ./private-module/nixos.nix
  ];

  systemd.services.testServiceFunc = lib.custom.mkInternetService { 
    sessionName = "test-ping";
    username = "dobiko";
    script = pkgs.writeScript "le-ebic-service" ''
      echo $(nix eval --expr '1 + 2') | tee ~/hometest.txt;
      who;
      ping www.google.de;
      '';
  };
}