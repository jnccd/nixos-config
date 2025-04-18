{ config, lib, pkgs, stateVersion, username, ... }: let 
  runnerUsername = "runner";
in {
  imports = [ 
    (import ./private-module/nixos.nix { inherit config lib pkgs stateVersion username runnerUsername; }) 
  ];

  users.users."${runnerUsername}" = {
    isNormalUser = true;
    description = runnerUsername;
    extraGroups = [];
    packages = [];
  };

  systemd.services = lib.custom.registerScreenService { 
    sessionName = "test-ping";
    username = runnerUsername;
    script = pkgs.writeScript "le-ebic-service" ''
        ${lib.custom.bashEnsureInternet}

        cd ~ && mkdir runner-test; cd runner-test

        (echo $(nix eval --expr '1 + 2') | tee hometest.txt) > log1.txt 2>&1 &&
        who > log2.txt 2>&1 &&
        ping www.google.de > log3.txt 2>&1
      '';
  };
}