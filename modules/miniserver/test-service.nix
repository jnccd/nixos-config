{ config, lib, pkgs, globalArgs, ... }:
let runnerName = globalArgs.defaultSystemUsername + "-test";
in {
  # - User -

  userMngmnt.additionalUsers = [{
    name = runnerName;
    isAdmin = false;
    isSystem = true;
  }];

  # - Sops-Nix -

  sops.secrets.example_key = {
    sopsFile = ../../secrets/main.yaml;
    owner = runnerName;
  };

  # - Service -

  systemd.services = lib.custom.mkWrappedScreenService {
    sessionName = "test";
    username = runnerName;
    scriptDirName = "test";
    script = pkgs.writeScript "script" ''
      who
      pwd
      export EXAMPLE_KEY=$(cat ${config.sops.secrets.example_key.path})
      echo $EXAMPLE_KEY
    '';
  };
}
