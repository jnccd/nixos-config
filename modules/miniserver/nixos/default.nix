{ config, lib, pkgs, stateVersion, globalArgs, ... }: 
{
  imports = [ 
    ../private-module/nixos
    ./test-service.nix
  ];

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
}