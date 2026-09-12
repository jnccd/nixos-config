{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dobikoConf.jellyfin-desktop;
in
{
  options.dobikoConf.jellyfin-desktop = {
    enabled = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Wrap jellyfin-desktop so its native MPV player actually registers.
      '';
    };

    serverUrl = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "http://minis:8096/web/";
      description = ''
        Web client URL jellyfin-desktop should load on startup.
      '';
    };
  };

  config = lib.mkIf cfg.enabled {
    assertions = [
      {
        assertion = cfg.serverUrl != "";
        message = "dobikoConf.jellyfin-desktop.serverUrl must be set when the wrapper is enabled.";
      }
    ];

    # Why this wrapper exists.
    #
    # jellyfin-desktop 2.0.0 starts on its bundled qrc:///web-client/extension/
    # find-webclient.html page, and that page navigates to the server with
    # `window.location = resolvedUrl` (a renderer-initiated navigation). On the
    # QtWebEngine 6.11 in nixpkgs that navigation does not run the injected
    # NativeShell bootstrap script, so the server page ends up with no
    # window.jmpInfo / window.NativeShell / window._mpvVideoPlayer. jellyfin-web
    # then never registers the native `mpvVideoPlayer` plugin and falls back to
    # its HTML5 player, i.e. Chromium.
    #
    # That matters on this Intel iGPU: Chromium hardware-decodes 10-bit video
    # but cannot allocate a shared image for the resulting (Y_UV, 420, 10unorm)
    # frame, so 10-bit playback is full of visual glitches. MPV handles the same
    # content fine (`VO: [libmpv] ... p010`).
    #
    # Loading the server URL directly makes the first load browser-initiated,
    # which does run the bootstrap script. This wrapper seeds that setting into
    # the active profile before every launch (idempotent), so it also repairs
    # an existing profile and works from a fresh install.
    nixpkgs.overlays = [
      (
        final: prev:
        let
          profileId = "nixos";

          seedProfiles = prev.writeText "jellyfin-desktop-profiles.json" (
            builtins.toJSON { defaultProfile = profileId; }
          );

          seedConfig = prev.writeText "jellyfin-desktop.conf" (
            builtins.toJSON {
              version = 7;
              sections.path = {
                startupurl_desktop = cfg.serverUrl;
                startupurl_extension = "bundled";
              };
            }
          );

          seedScript = prev.writeText "jellyfin-desktop-seed.py" ''
            import json
            import sys

            conf, url = sys.argv[1], sys.argv[2]
            try:
                data = json.load(open(conf))
            except (OSError, ValueError):
                data = {}
            data.setdefault("sections", {}).setdefault("path", {})["startupurl_desktop"] = url
            with open(conf, "w") as handle:
                json.dump(data, handle, indent=4)
          '';

          launcher = prev.writeShellScriptBin "jellyfin-desktop" ''
            set -e
            data_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/jellyfin-desktop"
            mkdir -p "$data_dir/profiles"

            if [ ! -e "$data_dir/profiles.json" ]; then
              cat ${seedProfiles} > "$data_dir/profiles.json"
            fi

            profile="$(${prev.python3}/bin/python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("defaultProfile", ""))' "$data_dir/profiles.json")"
            if [ -z "$profile" ]; then
              profile=${profileId}
              printf '{"defaultProfile":"%s"}\n' "$profile" > "$data_dir/profiles.json"
            fi

            conf="$data_dir/profiles/$profile/jellyfin-desktop.conf"
            if [ ! -e "$conf" ]; then
              mkdir -p "$(dirname "$conf")"
              cat ${seedConfig} > "$conf"
            fi

            ${prev.python3}/bin/python3 ${seedScript} "$conf" ${lib.escapeShellArg cfg.serverUrl}

            exec ${prev.jellyfin-desktop}/bin/jellyfin-desktop "$@"
          '';
        in
        {
          jellyfin-desktop = prev.symlinkJoin {
            name = "jellyfin-desktop-${prev.jellyfin-desktop.version}-wrapped";
            paths = [ prev.jellyfin-desktop ];
            postBuild = ''
              rm -f $out/bin/jellyfin-desktop
              ln -s ${launcher}/bin/jellyfin-desktop $out/bin/jellyfin-desktop
            '';
          };
        }
      )
    ];
  };
}
