{ config, lib, pkgs, globalArgs, ... }:
let
  uidRangeCount = 65536;

  mkUser = index: user: {
    name = user.name;
    value = {
      description = user.name;
      isNormalUser = !user.isSystem;
      isSystemUser = user.isSystem;

      uid = lib.mkIf (user ? uid) user.uid;

      group = user.name;
      extraGroups = if user.isAdmin then [
        "networkmanager"
        "input"
        "wheel"
        "nginx"
        "scanner"
        "lp"
      ] else
        [ ];

      subUidRanges = [{
        startUid = 100000 + uidRangeCount * index;
        count = uidRangeCount;
      }];
      subGidRanges = [{
        startGid = 100000 + uidRangeCount * index;
        count = uidRangeCount;
      }];

      home = lib.mkIf user.isSystem "/srv/${user.name}/";

      createHome = true;
      useDefaultShell = true;
    };
  };

  mkGroup = index: user: {
    name = user.name;
    value = { gid = lib.mkIf (user ? gid) user.gid; };
  };
in {
  options.dobikoConf.userMngmnt.additionalUsers = lib.mkOption {
    type = lib.types.listOf lib.types.attrs;
    default = [ ];
    description = "The users to add to the system";
  };

  config = let
    usersToDefine = config.dobikoConf.userMngmnt.additionalUsers ++ [
      {
        name = globalArgs.mainUsername;
        isAdmin = true;
        isSystem = false;
        uid = 1000;
        gid = 1000;
      }
      {
        name = globalArgs.defaultSystemUsername;
        isAdmin = false;
        isSystem = true;
        uid = 900;
        gid = 900;
      }
    ];
  in {
    users.defaultUserShell = pkgs.bash;

    users.users = builtins.listToAttrs (pkgs.lib.imap0 mkUser usersToDefine);
    users.groups = builtins.listToAttrs (pkgs.lib.imap0 mkGroup usersToDefine);
  };
}
