{ config, lib, pkgs, globalArgs, ... }:
let
  uidRangeCount = 65536;

  mkUser = index: user: {
    name = user.name;
    value = {
      description = user.name;
      isNormalUser = !user.isSystem;
      isSystemUser = user.isSystem;

      uid = lib.mkIf (user ? defaultUid) user.defaultUid;

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
      shell = lib.mkIf (user ? shell) user.shell;

      createHome = true;
      useDefaultShell = lib.mkIf (!(user ? shell)) true;
    };
  };

  mkGroup = index: user: {
    name = user.name;
    value = { gid = lib.mkIf (user ? defaultGid) user.defaultGid; };
  };
in {
  options.dobikoConf.userMngmnt.additionalUsers = lib.mkOption {
    type = lib.types.listOf lib.types.attrs;
    default = [ ];
    description = "The users to add to the system";
  };

  config = let
    usersToDefine = config.dobikoConf.userMngmnt.additionalUsers
      ++ globalArgs.baseUsers;
  in {
    users.defaultUserShell = pkgs.bash;

    users.users = builtins.listToAttrs (pkgs.lib.imap0 mkUser usersToDefine);
    users.groups = builtins.listToAttrs (pkgs.lib.imap0 mkGroup usersToDefine);
  } //
  # Postgres db access setup

  (let
    dbAccessUsernames = (map (user: user.name)
      (builtins.filter (user: user ? dbAccess && user.dbAccess) usersToDefine));
    dbSopsSecrets = map (username: {
      name = "postgres/pass/${lib.custom.userNameToPostgresRoleName username}";
      value = { owner = username; };
    }) dbAccessUsernames;
  in {
    sops.secrets = lib.mkIf config.dobikoConf.postgres.enabled
      (builtins.listToAttrs dbSopsSecrets);
    systemd.services = lib.mkIf config.dobikoConf.postgres.enabled
      (lib.attrsets.mergeAttrsList (builtins.map (username:
        lib.custom.mkWrappedScreenService {
          sessionName = "psql-init-${username}";
          username = "root";
          scriptDirName = "psql-init-${username}";
          after = [ "postgresql.service" ];
          script = let
            psqlUsername = lib.custom.userNameToPostgresRoleName username;
            createRoleScript = pkgs.writeScript "create-role-script" ''
              ${pkgs.postgresql}/bin/psql -U postgres -c "DO \$\$ BEGIN
                IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${psqlUsername}') THEN
                  CREATE ROLE ${psqlUsername} LOGIN PASSWORD '$PSQL_PASS' CREATEDB INHERIT;
                END IF;
              END \$\$;"'';
            createDbScript = pkgs.writeScript "create-db-script" ''
              ${pkgs.postgresql}/bin/psql -U postgres -c "CREATE DATABASE ${psqlUsername} OWNER ${psqlUsername};"'';
          in pkgs.writeScript "script" ''
            sleep 1
            export PSQL_PASS=$(cat ${
              config.sops.secrets."postgres/pass/${psqlUsername}".path
            })

            sudo -iu postgres bash ${createRoleScript}
            sudo -iu postgres bash ${createDbScript}
          '';
        }) dbAccessUsernames));
  });
}
