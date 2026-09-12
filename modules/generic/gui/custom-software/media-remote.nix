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
        # The desktop wrapper is this flake's default package.
        flakeAttr = "default";

        # Main user only. The server binds the fixed port below, and it also
        # needs this user's sops secret, so a second desktop account running its
        # own copy is not just wasteful: the copy aborts on the port clash and
        # dumps a core file at login.
        onlyUser = globalArgs.mainUser.name;

        # `nix-rb`'s equivalent for this repo. Runs only when the revision
        # changed. The out-link lands in the repo's clone (gitignored) because
        # `artifacts` is resolved relative to the repo, and the success marker is
        # written here rather than by the launcher: with `nix build` the exit
        # status is what tells a good build from a bad one.
        buildCommand = ''
          mkdir -p "$repo/.nix-build"
          if nix build "$repo#default" --out-link "$repo/.nix-build/current"; then
            printf '%s\n' "$now" > "$state_dir/built"
          else
            echo "gui-autostart media-remote: nix build failed for $now" >&2
            exit 1
          fi
        '';

        envScript = ''
          export PASSWORD="$(cat "${config.sops.secrets."media_remote/pass".path}")"
          export PORT=${toString PORT}
          # WebKitGTK 2.52 under KWin/Wayland leaves the Tauri webview unpainted:
          # the window comes up blank and even its window buttons only respond
          # after a maximise/unmaximise forces a repaint. Its DMA-BUF renderer is
          # the usual cause, so fall back to the shared-memory path. If the
          # window still misbehaves, WEBKIT_DISABLE_COMPOSITING_MODE=1 is the
          # heavier hammer.
          export WEBKIT_DISABLE_DMABUF_RENDERER=1
        '';

        # The built app. The package also installs the MediaControlServer it
        # spawns, right next to this binary (src-tauri probes for it there).
        launchCommand = ''"$repo/.nix-build/current/bin/media-control-desktop"'';

        # Must match what the build command links. Used to tell whether anything
        # is runnable at all, and as the fallback when a build fails.
        artifacts = [ ".nix-build/current/bin/media-control-desktop" ];

        # Keep the build output visible; the package's own wrapper already sets
        # LD_LIBRARY_PATH for the dlopen()ed tray library.
        screenWrap = true;
      };
    };
}
