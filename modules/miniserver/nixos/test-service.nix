{ config, lib, pkgs, stateVersion, mainUsername, runnerUsername, ... }:
{
  # --- Sops-Nix ---

  sops.secrets.example_key = {
    owner = runnerUsername;
  };

  # --- Services ---

  systemd.services = lib.custom.mkWrappedScreenService { 
    sessionName = "test";
    username = runnerUsername;
    scriptDirName = "test";
    script = pkgs.writeScript "script" ''
        who
        pwd
        export EXAMPLE_KEY=$(cat ${config.sops.secrets.example_key.path})
        echo $EXAMPLE_KEY
      '';
  };
}