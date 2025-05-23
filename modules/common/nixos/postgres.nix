{ config, lib, pkgs, globalArgs, ... }: {
  # - Sops-Nix -
  sops.secrets."postgres/pass" = { owner = "postgres"; };

  # - Services -
  services.postgresql.enable = true;
  systemd.services = lib.custom.mkWrappedScreenService {
    sessionName = "psql-init";
    username = "postgres";
    scriptDirName = "psql-init";
    requirements = [ "postgresql.service" ];
    script = pkgs.writeScript "script" ''
      export psql_pass=$(cat ${config.sops.secrets."postgres/pass".path})
      ${pkgs.postgresql}/bin/psql -U postgres -c "DO \$\$ BEGIN
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${globalArgs.mainUsername}') THEN
          CREATE ROLE ${globalArgs.mainUsername} LOGIN PASSWORD '$psql_pass' CREATEDB INHERIT;
          CREATE DATABASE ${globalArgs.mainUsername} OWNER ${globalArgs.mainUsername};
        END IF;

        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${globalArgs.defaultSystemUsername}') THEN
          CREATE ROLE ${globalArgs.defaultSystemUsername} LOGIN PASSWORD '$psql_pass' CREATEDB INHERIT;
        END IF;
      END \$\$;"
    '';
  };
}
