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
    subUidRanges = [ { startUid = 200000; count = 65536; } ];
    subGidRanges = [ { startGid = 200000; count = 65536; } ];
  };
  users.groups."${globalArgs.defaultSystemUsername}" = {};
}