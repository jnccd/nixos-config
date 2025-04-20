{ config, lib, pkgs, stateVersion, username, ... }: let 
  runnerUsername = "runner";
in {
  imports = [ 
    (import ./private-module/nixos.nix { inherit config lib pkgs stateVersion username runnerUsername; }) 
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

  # --- Services ---

  systemd.services = lib.custom.mkWrappedScreenService { 
    sessionName = "test";
    username = runnerUsername;
    scriptDirName = "test";
    script = pkgs.writeScript "script" ''
        who
        pwd
      '';
  };
}