{ config, lib, pkgs, globalArgs, ... }: {
  # - Sops-Nix -
  sops.secrets."postgres/pass" = { owner = "postgres"; };

  # - Services -
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
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
}
