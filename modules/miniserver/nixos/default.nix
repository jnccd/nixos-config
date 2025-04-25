{ config, lib, pkgs, stateVersion, mainUsername, ... }: let 
  runnerUsername = "runner";
in {
  imports = [ 
    (import ../private-module/nixos { inherit config lib pkgs stateVersion mainUsername runnerUsername; })
    (import ./test-service.nix { inherit config lib pkgs stateVersion mainUsername runnerUsername; })
  ];

  # --- Runner User ---

  users.users."${runnerUsername}" = {
    description = runnerUsername;

    home = "/srv/${runnerUsername}/";
    createHome = true;
    useDefaultShell = true;

    isSystemUser = true;
    group = "${runnerUsername}";
  };
  users.groups."${runnerUsername}" = {};
}