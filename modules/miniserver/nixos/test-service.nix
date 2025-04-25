{ config, lib, pkgs, stateVersion, globalArgs, ... }:
{
  # --- Sops-Nix ---

  sops.secrets.example_key = {
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