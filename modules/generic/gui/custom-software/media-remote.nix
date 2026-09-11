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

  config = lib.mkIf config.dobikoConf.media-remote.enabled {
    environment.etc = lib.custom.mkGuiAppAutostart {
      appName = "media-remote";
      repoName = "media-remote";
      repoUrl = "https://github.com/jnccd/media-remote";
      # The desktop wrapper is this flake's default package.
      flakeAttr = "default";

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
