{ config, lib, pkgs, globalArgs, ... }:
{
  # --- Runner User ---

  users.users."${globalArgs.defaultSystemUsername}" = {
    description = globalArgs.defaultSystemUsername;

    home = "/srv/${globalArgs.defaultSystemUsername}/";
    createHome = true;
    useDefaultShell = true;

    isSystemUser = true;
    group = "${globalArgs.defaultSystemUsername}";
  };
  users.groups."${globalArgs.defaultSystemUsername}" = {};

  # --- Sops-Nix ---

  sops.secrets.example_key = {
    sopsFile = ../../secrets/main.yaml;
    owner = globalArgs.defaultSystemUsername;
  };

  # --- Services ---

  systemd.services = lib.custom.mkWrappedScreenService { 
    sessionName = "test";
    username = globalArgs.defaultSystemUsername;
    scriptDirName = "test";
    script = pkgs.writeScript "script" ''
        who
        pwd
        export EXAMPLE_KEY=$(cat ${config.sops.secrets.example_key.path})
        echo $EXAMPLE_KEY
      '';
  };
}