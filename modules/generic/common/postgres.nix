{ config, lib, pkgs, globalArgs, ... }: {
  options.dobikoConf.postgres.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enables postgres";
  };

  config = let
    usernames =
      (map (user: user.name) config.dobikoConf.userMngmnt.additionalUsers)
      ++ [ globalArgs.mainUsername globalArgs.defaultSystemUsername ];
    sopsSecrets = map (username: {
      name = "postgres/pass/${lib.custom.userNameToPostgresRoleName username}";
      value = { owner = username; };
    }) usernames;
  in lib.mkIf config.dobikoConf.postgres.enabled {
    # - Sops-Nix -
    sops.secrets = builtins.listToAttrs sopsSecrets;

    # - Services -
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_16;

      # Tuned for SSDs using https://pgtune.leopard.in.ua
      settings = {
        max_connections = 200;
        shared_buffers = "512MB";
        effective_cache_size = "1536MB";
        maintenance_work_mem = "128MB";
        checkpoint_completion_target = 0.9;
        wal_buffers = "16MB";
        default_statistics_target = 100;
        random_page_cost = 1.1;
        effective_io_concurrency = 200;
        work_mem = "2570kB";
        huge_pages = "off";
        min_wal_size = "1GB";
        max_wal_size = "4GB";
        max_worker_processes = 4;
        max_parallel_workers_per_gather = 2;
        max_parallel_workers = 4;
        max_parallel_maintenance_workers = 2;
      };
    };
    systemd.services = lib.attrsets.mergeAttrsList (builtins.map (username:
      lib.custom.mkWrappedScreenService {
        sessionName = "psql-init-${username}";
        username = username;
        scriptDirName = "psql-init-${username}";
        after = [ "postgresql.service" ];
        script =
          let psqlUsername = lib.custom.userNameToPostgresRoleName username;
          in pkgs.writeScript "script" ''
            sleep 1
            export psql_pass=$(cat ${
              config.sops.secrets."postgres/pass/${psqlUsername}".path
            })
            ${pkgs.postgresql}/bin/psql -U postgres -c "DO \$\$ BEGIN
              IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${psqlUsername}') THEN
                CREATE ROLE ${psqlUsername} LOGIN PASSWORD '$psql_pass' CREATEDB INHERIT;
              END IF;
            END \$\$;"
            ${pkgs.postgresql}/bin/psql -U postgres -c "CREATE DATABASE ${psqlUsername} OWNER ${psqlUsername};"
          '';
      }) usernames);
  };
}
