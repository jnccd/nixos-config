{ config, lib, pkgs, globalArgs, ... }: 
{
  imports = [ 
    ./private-module
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