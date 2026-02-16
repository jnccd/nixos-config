{ config, lib, pkgs, globalArgs, ... }: {
  options.dobikoConf.postgres.enabled = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enables postgres";
  };

  config = lib.mkIf config.dobikoConf.postgres.enabled {
    # - Services -
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_18;
      # An upgrade guide is in the readme.md

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
