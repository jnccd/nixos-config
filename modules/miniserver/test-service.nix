{ config, lib, pkgs, globalArgs, ... }:
{
  # --- Sops-Nix ---

  sops.secrets.example_key = {
    sopsFile = ../../secrets/main.yaml;
    owner = globalArgs.defaultSystemUsername;
  };

  # --- Service ---

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