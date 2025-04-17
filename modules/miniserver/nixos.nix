{ config, lib, pkgs, stateVersion, username, ... }: let

  mkInternetService = sessionName: user: script: {
    enable = true;
    description = sessionName;

    requires = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      User = user;

      ExecStart = pkgs.writeScript "${sessionName}-start-script" ''
            #!${pkgs.runtimeShell}
            PATH=$PATH:/run/current-system/sw/bin
            screen -S ${sessionName} -dm bash -c "${script}";
            while :; do sleep 2073600; done
          '';
      ExecStop = pkgs.writeScript "${sessionName}-start-script" ''
            #!${pkgs.runtimeShell}
            PATH=$PATH:/run/current-system/sw/bin
            screen -XS ${sessionName} quit
          '';
    };
  };
  
in {
  imports = [
    ./private-module/nixos.nix
  ];

  systemd.services.testServiceFunc = mkInternetService "test-ping-f" "dobiko" "ping www.google.de";
}