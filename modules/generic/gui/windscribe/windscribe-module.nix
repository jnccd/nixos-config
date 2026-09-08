# Optional NixOS module that wires the Windscribe derivation into a system.
#
# Copy this file next to drv.nix, e.g. as
#   modules/generic/gui/windscribe/windscribe-module.nix
# and make sure the directory is imported in your configuration (the
# listAllLocalImportables auto-import in modules/generic does this).
#
# drv.nix itself must NEVER be added to `imports` - it is a function returning
# a derivation, not a module. It is called from this module instead.
{ config, lib, pkgs, globalArgs ? null, ... }:
let
  windscribe-gui = import ./drv.nix { inherit pkgs; };
  mainUser = if globalArgs != null && globalArgs ? mainUser then globalArgs.mainUser.name else "dobiko";

  # Tools the helper and its DNS/leak-protection scripts shell out to. The
  # systemd service gets these on its PATH (systemd's default service PATH is
  # only coreutils/systemd); note that update-resolv-conf is already patched in
  # drv.nix with these same tools on its own PATH, because OpenVPN runs it with
  # a sanitized PATH=/no-such-path.
  helperTools = [
    pkgs.iptables
    pkgs.nftables
    pkgs.iproute2
    pkgs.iputils
    pkgs.iw
    pkgs.procps
    pkgs.psmisc
    pkgs.gnupg
    pkgs.nettools
    pkgs.acl
    pkgs.openresolv # resolvconf, required by update-resolv-conf
    pkgs.gawk # awk, required by dns-leak-protect (without it DNS leaks)
    pkgs.util-linux # logger, required by update-systemd-resolved
  ];
in
{
  environment.systemPackages = [ windscribe-gui ];

  # The helper hardcodes /opt/windscribe as its application directory
  # (WS_LINUX_INSTALL_DIR) and refuses to run any bundled executable
  # (wireguard/openvpn/ctrld/wstunnel) unless the resolved directory is
  # exactly /opt/windscribe. Bind-mount the store contents there - a plain
  # symlink would NOT work, because realpath() would resolve it to the store
  # path and the check would still fail.
  fileSystems."/opt/windscribe" = {
    device = "${windscribe-gui}/opt/windscribe";
    fsType = "none";
    options = [ "bind" ];
  };

  # The helper runs its obfuscation proxies (stunnel/wstunnel) as this system
  # user and the firewall rules match its uid (the DEB's postinst creates it).
  users.users.windscribe = {
    isSystemUser = true;
    group = "windscribe";
  };
  users.groups.windscribe = { };

  # The helper creates its socket as root:windscribe mode 0770, so the user
  # running the GUI must be a member of the group (takes effect after re-login).
  users.users."${mainUser}".extraGroups = [ "windscribe" ];

  # The privileged helper service (mirrors the systemd unit shipped in the
  # official .deb, which its postinst enables).
  systemd.services.windscribe-helper = {
    description = "Windscribe helper service";
    wantedBy = [ "multi-user.target" ];
    # systemd services get a minimal PATH (coreutils/systemd only); the helper
    # shells out to iptables-restore, ip, nft, resolvectl, killall, ... which
    # are not on that default PATH.
    path = helperTools;
    serviceConfig = {
      Type = "simple";
      ExecStart = "${windscribe-gui}/opt/windscribe/helper";
    };
  };
}
