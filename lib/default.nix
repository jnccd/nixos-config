{ pkgs, ... }: rec {
  bashEnsureInternet = "until host www.google.de; do sleep 30; done";
  bashWaitForever = "while :; do sleep 2073600; done";

  mkScreenService = { sessionName, username, script }: {
    "${sessionName}" = {
      enable = true;
      description = sessionName;

      wantedBy = [ "multi-user.target" ];
      requires = [ "network-online.target" ];

      environment = {
        NIX_PATH =
          "nixpkgs=flake:nixpkgs:/nix/var/nix/profiles/per-user/root/channels";
      };

      serviceConfig = {
        User = username;

        ExecStart = pkgs.writeScript "${sessionName}-start-script" ''
          #!${pkgs.runtimeShell}
          PATH=$PATH:/run/current-system/sw/bin
          screen -S ${sessionName} -dm bash -c "${script}";
          ${bashWaitForever}
        '';
        ExecStop = pkgs.writeScript "${sessionName}-stop-script" ''
          #!${pkgs.runtimeShell}
          PATH=$PATH:/run/current-system/sw/bin
          screen -XS ${sessionName} quit
        '';
      };
    };
  };
  mkWrappedScreenService = { sessionName, username, scriptDirName, script }:
    mkScreenService {
      inherit sessionName username;
      script = pkgs.writeScript "wrapped-service-script" ''
        ${bashEnsureInternet}
        cd ~ && mkdir -p screen-runs/${scriptDirName}; cd screen-runs/${scriptDirName};
        clear;

        ${script}

        ${bashWaitForever}
      '';
    };
}
