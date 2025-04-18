{ config, lib, pkgs, stateVersion, username, ... }:
{
  imports = [
    ./private-module/nixos.nix
  ];

  systemd.services.testServiceFunc = lib.custom.mkScreenService { 
    sessionName = "test-ping";
    username = "dobiko";
    script = pkgs.writeScript "le-ebic-service" ''
        ${lib.custom.bashEnsureInternet}

        (echo $(nix eval --expr '1 + 2') | tee ~/hometest.txt) > ~/log1.txt 2>&1 &&
        who > ~/log2.txt 2>&1 &&
        ping www.google.de > ~/log3.txt 2>&1
      '';
  };
}