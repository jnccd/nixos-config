{ config, lib, pkgs, globalArgs, ... }:
let
  netInterface = "wg0";
  port = 8999;
in {
  options.dobikoConf.qbittorrent.enabled = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enables qbittorrent, expects a network interface named "
      + netInterface;
  };

  config = lib.mkIf config.dobikoConf.qbittorrent.enabled {
    networking.firewall.allowedTCPPorts = [ 8080 port ];
    networking.firewall.allowedUDPPorts = [ port ];
    services.qbittorrent = {
      enable = true;
      openFirewall = true;
      serverConfig = {
        Preferences = {
          WebUI = {
            Username = "admin";
            Password_PBKDF2 =
              "yj3E7aI9w79UWK0KI3nF6g==:3go76xLgL9Sc163RBlyYpoi7w+n108S1kftYiFGPabfvQDmsg3YuRPlecnIm7R+6FD2+jXH2UxSMPDJOUktP9w=="; # generated with https://codeberg.org/feathecutie/qbittorrent_password
          };
          General.Locale = "en";
          Connection.Interface = netInterface;
        };
        BitTorrent.Session = { Port = port; };
      };
    };
    systemd.services.qbittorrent.serviceConfig.BindToDevice = netInterface;
  };
}
