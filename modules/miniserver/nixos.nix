{ config, lib, pkgs, stateVersion, mainUsername, ... }: let 
  runnerUsername = "runner";
in {
  imports = [ 
    (import ./private-module/nixos.nix { inherit config lib pkgs stateVersion mainUsername runnerUsername; }) 
  ];

  # --- Runner User ---

  users.users."${runnerUsername}" = {
    description = runnerUsername;

    home = "/srv/${runnerUsername}/";
    createHome = true;
    useDefaultShell = true;

    isSystemUser = true;
    group = "${runnerUsername}";
    extraGroups = [ 
      "nginx" # For certs :/
    ];
  };
  users.groups."${runnerUsername}" = {};

  # --- Firewall ---

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # --- ACME ---

  security.acme = {
    acceptTerms = true;
    defaults.email = "kobidogao@outlook.com";
  };

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
        export EXAMPLE_KEY=$(cat ${config.sops.secrets.example_key.path})
        echo $EXAMPLE_KEY
      '';
  };
}