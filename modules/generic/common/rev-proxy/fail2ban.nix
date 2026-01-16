{ config, lib, pkgs, globalArgs, ... }:
let
  fail2BanJailName = "nginx-access";
  fail2BanActionName = "log-bans";
in {
  services.fail2ban = {
    enable = true;
    maxretry = 4;
    ignoreIP = [ "192.168.0.0/16" ];
    bantime = "3m";
    bantime-increment = {
      enable = true;
      multipliers = "1 4 8 16 32 64 128 256 512";
      maxtime = "24h";
      overalljails = true;
    };
    jails = {
      "${fail2BanJailName}".settings = {
        enabled = true;
        filter = "${fail2BanJailName}";
        logpath = "/var/log/nginx/access.log";
        action = ''
          %(action_)s[blocktype=DROP]
                           ${fail2BanActionName}'';
        backend = "auto";
      };
    };
  };
  environment.etc = {
    "fail2ban/filter.d/${fail2BanJailName}.local".text = pkgs.lib.mkAfter ''
      [Definition]
      failregex = ^<HOST>.*"(GET|POST|HEAD).*(phpunit|wp-includes|wp-content|wp-trackback|wp-admin|\.\./\.\./| 404 ).*"
      ignoreregex =
    '';
    "fail2ban/action.d/${fail2BanActionName}.local".text = pkgs.lib.mkAfter ''
      [Definition]
      norestored = true # Needed to avoid receiving a new notification after every restart
      actionban = echo "$(date) <name> jail has banned <ip> from accessing $(hostname) after <failures> attempts" >> /var/log/fail2ban/ban.log
    '';
  };
}
