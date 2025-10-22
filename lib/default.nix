{ pkgs, lib, ... }: rec {
  bashEnsureInternet = "until host www.google.de; do sleep 30; done";
  bashWaitForever = "while :; do sleep 2073600; done";

  mkScreenService = { sessionName, username, script
    , wantedBy ? [ "multi-user.target" ], requires ? [ ], after ? [ ] }: {
      "${sessionName}" = {
        enable = true;
        description = sessionName;

        wantedBy = wantedBy;
        requires = requires;
        after = after;

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
  mkWrappedScreenService = { sessionName, username, scriptDirName, script
    , wantedBy ? [ "multi-user.target" ], requires ? [ "network-online.target" ]
    , after ? [ ] }:
    mkScreenService {
      inherit sessionName username wantedBy requires after;
      script = pkgs.writeScript "wrapped-service-script" ''
        ${bashEnsureInternet}
        cd ~ && mkdir -p screen-runs/${scriptDirName}; cd screen-runs/${scriptDirName};
        clear;
        date;

        ${script}

        ${bashWaitForever}
      '';
    };

  listAllLocalImportables = path:
    builtins.map (f: (path + "/${f}")) (builtins.attrNames
      (lib.attrsets.filterAttrs (path: _type:
        (_type == "directory") # include directories
        || ((path != "default.nix") # ignore default.nix
          && (lib.strings.hasSuffix ".nix" path) # include .nix files
        )) (builtins.readDir path)));
}
