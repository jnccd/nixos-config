{ config, lib, pkgs, globalArgs, ... }:
{
  # --- Main User ---

  users.defaultUserShell = pkgs.bash;
  users.users.${globalArgs.mainUsername} = {
    description = globalArgs.mainUsername;
    isNormalUser = true;

    extraGroups = [ "networkmanager" "input" "wheel" "nginx" ];
    subUidRanges = [ { startUid = 100000; count = 65536; } ];
    subGidRanges = [ { startGid = 100000; count = 65536; } ];
  };

  # --- Runner User ---

  users.users."${globalArgs.defaultSystemUsername}" = {
    description = globalArgs.defaultSystemUsername;
    isSystemUser = true;

    group = "${globalArgs.defaultSystemUsername}";
    subUidRanges = [ { startUid = 200000; count = 65536; } ];
    subGidRanges = [ { startGid = 200000; count = 65536; } ];
    
    home = "/srv/${globalArgs.defaultSystemUsername}/";
    createHome = true;
    useDefaultShell = true;
  };
  users.groups."${globalArgs.defaultSystemUsername}" = {};
}