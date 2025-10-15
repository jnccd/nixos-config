{ config, lib, pkgs, globalArgs, ... }: {
  options.dobikoConf.postgres.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enables postgres";
  };

  config = lib.mkIf config.dobikoConf.postgres.enabled {
    # - Sops-Nix -
    sops.secrets."postgres/pass" = { owner = "postgres"; };

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
    systemd.services = lib.custom.mkWrappedScreenService {
      sessionName = "psql-init";
      username = "postgres";
      scriptDirName = "psql-init";
      after = [ "postgresql.service" ];
      script = pkgs.writeScript "script" ''
        sleep 1
        export psql_pass=$(cat ${config.sops.secrets."postgres/pass".path})

        ${pkgs.postgresql}/bin/psql -U postgres -c "DO \$\$ BEGIN
          IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${globalArgs.mainUsername}') THEN
            CREATE ROLE ${globalArgs.mainUsername} LOGIN PASSWORD '$psql_pass' CREATEDB INHERIT;
          END IF;

          IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${globalArgs.defaultSystemUsername}') THEN
            CREATE ROLE ${globalArgs.defaultSystemUsername} LOGIN PASSWORD '$psql_pass' CREATEDB INHERIT;
          END IF;
        END \$\$;"
        ${pkgs.postgresql}/bin/psql -U postgres -c "CREATE DATABASE ${globalArgs.mainUsername} OWNER ${globalArgs.mainUsername};"
        ${pkgs.postgresql}/bin/psql -U postgres -c "CREATE DATABASE ${globalArgs.defaultSystemUsername} OWNER ${globalArgs.defaultSystemUsername};"
      '';
    };
  };
}
