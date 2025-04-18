{ pkgs, ... }: let 
  bashEnsureInternet = "until host www.google.de; do sleep 30; done";

  mkScreenService = { sessionName, username, script }: {
    "${sessionName}" = {
      enable = true;
      description = sessionName;

      wantedBy = [ "multi-user.target" ];
      requires = [ "network-online.target" ];

      serviceConfig = {
        User = username;

        ExecStart = pkgs.writeScript "${sessionName}-start-script" ''
            #!${pkgs.runtimeShell}
            PATH=$PATH:/run/current-system/sw/bin
            screen -S ${sessionName} -dm bash -c "${script}";
            while :; do sleep 2073600; done
          '';
        ExecStop = pkgs.writeScript "${sessionName}-stop-script" ''
            #!${pkgs.runtimeShell}
            PATH=$PATH:/run/current-system/sw/bin
            screen -XS ${sessionName} quit
          '';
      };
    };
  };
in {
  inherit bashEnsureInternet mkScreenService;
}