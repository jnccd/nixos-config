{ config, lib, pkgs, stateVersion, mainUsername, ... }: let 
  runnerUsername = "runner";
in {
  imports = [ 
    (import ./private-module/nixos.nix { inherit config lib pkgs stateVersion mainUsername runnerUsername; }) 
  ];

  # --- Runner User ---

  users.users."${runnerUsername}" = {
    isNormalUser = true;
    description = runnerUsername;
    extraGroups = [];
    packages = [];
  };

  # --- Firewall ---

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # --- Sops-Nix ---

  sops.secrets.example_key = {
    owner = runnerUsername;
  };
  sops.secrets."discord_bot/discord_token" = {
    owner = runnerUsername;
  };
  sops.secrets."discord_bot/lighthouse/user" = {
    owner = runnerUsername;
  };
  sops.secrets."discord_bot/lighthouse/pass" = {
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
        echo uwu
        cat ${config.sops.secrets.example_key.path}
      '';
  };
}