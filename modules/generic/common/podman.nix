{ config, lib, pkgs, globalArgs, ... }: {
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # Without this, podman containers can refuse to start after reboot
  systemd.tmpfiles.rules = [ "R! /tmp/storage-run-*" ];
}
