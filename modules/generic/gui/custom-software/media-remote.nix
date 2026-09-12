{
  config,
  lib,
  pkgs,
  globalArgs,
  ...
}:
{
  options.dobikoConf.media-remote.enabled = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Autostart the MediaControl desktop wrapper (Tauri app + bundled server).

      Unlike the .NET apps in this directory, this one is built with `nix build`
      rather than a flake dev shell, and the build is expensive (Rust + WebKit,
      several minutes), so the launcher builds it ONLY when the checked-out
      revision changes and otherwise starts the previously built binary.
    '';
  };

  config =
    let
      PORT = 7779;
    in
    lib.mkIf config.dobikoConf.media-remote.enabled {
      sops.secrets."media_remote/pass" = {
        owner = globalArgs.mainUser.name;
      };

      # --- Input injection (uinput + ydotool) ---------------------------------
      # The server injects keyboard/mouse/media input by shelling out to
      # `ydotool`, NOT through X11/XTest, so that it works on Wayland too. That
      # needs plumbing no package can provide, so without this the app starts and
      # serves its UI fine but every control silently does nothing.
      #
      # This used to be a separate media-control.nix copied from the repo's
      # nixos/modules/. It is the same program, so it lives here now; the module
      # name there is just the server's own branding (repo: media-remote, server:
      # MediaControl).
      boot.kernelModules = [ "uinput" ];

      # /dev/uinput is root-only (crw-------) unless this rule makes it
      # group-writable; ydotoold needs to open it.
      services.udev.extraRules = ''
        SUBSYSTEM=="misc", KERNEL=="uinput", GROUP="input", MODE="0660"
      '';

      users.groups.input = { };
      users.users.${globalArgs.mainUser.name}.extraGroups = [ "input" ];

      environment.systemPackages = [ pkgs.ydotool ];

      # ydotoold and the server's `ydotool` client must share the same user and
      # socket, so the daemon runs inside the logged-in session rather than as a
      # system service.
      systemd.user.services.ydotoold = {
        description = "ydotool daemon (MediaControl input injection)";
        wantedBy = [ "default.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.ydotool}/bin/ydotoold";
          Restart = "on-failure";
          RestartSec = "2";

          # The unit is installed for every account (nothing in NixOS scopes a
          # systemd.user unit to particular users), but only accounts in `input`
          # can open /dev/uinput. Without this, every other user starts the
          # daemon, gets "failed to open uinput device: Permission denied", and
          # restarts every 2s forever.
          ConditionUser = globalArgs.mainUser.name;
        };
      };

      networking.firewall.allowedTCPPorts = [
        PORT
      ];

      environment.etc = lib.custom.mkGuiAppAutostart {
        appName = "media-remote";
        repoName = "media-remote";
        repoUrl = "https://github.com/jnccd/media-remote";

        # Main user only. The server binds the fixed port below, and it also
        # needs this user's sops secret, so a second desktop account running its
        # own copy is not just wasteful: the copy aborts on the port clash and
        # dumps a core file at login.
        onlyUser = globalArgs.mainUser.name;

        # Built on the client from source, like notes and music-player, rather
        # than with `nix build`: the wrapper is a plain Avalonia app, so the
        # repo's own dev shell plus a `dotnet build` in start_desktop_app.sh is a
        # few seconds, and a new commit needs no per-revision Nix packaging.
        # `desktop` is the dev shell that carries the SkiaSharp native libraries.
        flakeAttr = "desktop";

        # What start_desktop_app.sh runs on its "unchanged" branch. The launcher
        # uses its existence to tell a successful build from a failed one. It is
        # the .dll, not the apphost next to it: the app is started through the
        # `dotnet` muxer, because the SDK-generated apphost mixes glibc versions
        # on NixOS and crashes before managed code runs.
        artifacts = [ "DesktopApp/bin/Release/net8.0/media-control-desktop.dll" ];

        envScript = ''
          export PASSWORD="$(cat "${config.sops.secrets."media_remote/pass".path}")"
          export PORT=${toString PORT}
        '';

        # Keep the app's stdout visible: the Avalonia wrapper echoes the server's
        # log to it, so `screen -r gui-media-remote-<user>-<session>` shows the
        # server's output.
        screenWrap = true;
      };
    };
}
