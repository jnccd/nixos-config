{ config, lib, pkgs, globalArgs, ... }: {
  options.dobikoConf.postgres.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enables postgres";
  };

  config = lib.mkIf config.dobikoConf.postgres.enabled {
    # - Services -
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql;
      # Upgrade (make sure /var/lib/postgresql/X is empty and /var/lib/postgresql/X-1 has data):
      # sudo -u postgres initdb -D /var/lib/postgresql/17
      # sudo -u postgres pg_upgrade -b "$(nix build --no-link --print-out-paths nixpkgs#postgresql_16.out)/bin" -B /run/current-system/sw/bin -d /var/lib/postgresql/16 -D /var/lib/postgresql/17

      # Tuned for SSDs using https://pgtune.leopard.in.ua
      settings = {
        max_connections = 50;
        shared_buffers = "256MB";
        effective_cache_size = "768MB";
        maintenance_work_mem = "64MB";
        checkpoint_completion_target = 0.9;
        wal_buffers = "7864kB";
        default_statistics_target = 100;
        random_page_cost = 1.1;
        effective_io_concurrency = 200;
        work_mem = "4854kB";
        huge_pages = "off";
        min_wal_size = "1GB";
        max_wal_size = "4GB";
        max_worker_processes = 4;
        max_parallel_workers_per_gather = 2;
        max_parallel_workers = 4;
        max_parallel_maintenance_workers = 2;
      };
    };
  };
}
