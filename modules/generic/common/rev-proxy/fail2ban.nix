{ config, lib, pkgs, globalArgs, ... }:
let
  notFoundJailName = "nginx-not-found";
  botJailName = "nginx-bot";
  logActionName = "log-bans";
in {
  services.fail2ban = {
    enable = true;
    ignoreIP = [ "192.168.0.0/16" ];
    bantime-increment = {
      enable = true;
      multipliers = "1 4 8 16 32 64 128 256 512";
      maxtime = "24h";
      overalljails = true;
    };
    jails = {
      "${notFoundJailName}".settings = {
        filter = "${notFoundJailName}";
        maxretry = 7;
        bantime = "1m";
        enabled = true;
        logpath = "/var/log/nginx/access.log";
        action = ''
          %(action_)s[blocktype=DROP]
                           ${logActionName}'';
        backend = "auto";
      };
      "${botJailName}".settings = {
        filter = "${botJailName}";
        maxretry = 2;
        bantime = "4m";
        enabled = true;
        logpath = "/var/log/nginx/access.log";
        action = ''
          %(action_)s[blocktype=DROP]
                           ${logActionName}'';
        backend = "auto";
      };
    };
  };
  environment.etc = {
    "fail2ban/filter.d/${notFoundJailName}.local".text = pkgs.lib.mkAfter ''
      [Definition]
      failregex = ^<HOST>.*"(GET|POST|HEAD).* 404 .*"
      ignoreregex =
    '';
    "fail2ban/filter.d/${botJailName}.local".text = pkgs.lib.mkAfter ''
      [Definition]
      failregex = ^<HOST>.*"(GET|POST|HEAD).*(phpunit|wp-includes|wp-content|wp-trackback|wp-admin|\.\./\.\./).*"
      ignoreregex =
    '';
    "fail2ban/action.d/${logActionName}.local".text = pkgs.lib.mkAfter ''
      [Definition]
      norestored = true # Needed to avoid receiving a new notification after every restart
      actionban = echo "$(date) <name> jail has banned <ip> from accessing $(hostname) after <failures> attempts" >> /var/log/fail2ban/ban.log
    '';
  };
}
