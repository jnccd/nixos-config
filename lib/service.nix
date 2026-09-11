{ pkgs, lib }:
rec {
  bashEnsureInternet = "until host www.google.de; do sleep 30; done";
  bashWaitForever = "while :; do sleep 2073600; done";
  # Reconstruct a user's session environment for a *system* service that has to
  # reach into their session (e.g. bedtime.nix's kdialog warning, which runs
  # from a system timer as the main user). GUI autostart deliberately does NOT
  # use this any more: a .desktop launched by KDE already has the real session
  # environment, so nothing needs reconstructing.
  bashGetUserEnvVars =
    username:
    "export USER=${username} XDG_RUNTIME_DIR=/run/user/$(id -u ${username}) DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u ${username})/bus && eval $(systemctl --user show-environment | xargs -0 -I {} echo export {})";
  systemdExecWrapper =
    script:
    pkgs.writeScript "systemdExecWrapper-script" ''
      #!${pkgs.runtimeShell}
      PATH=$PATH:/run/current-system/sw/bin
      ${script}
    '';
  scriptForceRefreshGitRepo =
    repoPath:
    pkgs.writeScript "for-refresh-git-repo-script" ''
      git -C ${repoPath} reset --hard
      git -C ${repoPath} pull
      git -C ${repoPath} submodule update --init --recursive --force # Dont update --recursive --remote, keep linked versions
    '';

  mkScreenService =
    {
      sessionName,
      username,
      script,
      wantedBy ? [ "multi-user.target" ],
      requires ? [ ],
      after ? [ ],
      cleanupScript ? "",
      extraServiceConfig ? { },
    }:
    {
      "${sessionName}" = {
        enable = true;
        description = sessionName;

        wantedBy = wantedBy;
        requires = requires;
        after = after;

        environment = {
          NIX_PATH = "nixpkgs=flake:nixpkgs:/nix/var/nix/profiles/per-user/root/channels";
        };

        serviceConfig = {
          User = username;

          ExecStart = systemdExecWrapper ''
            screen -S ${sessionName} -dm bash -c "${script}";
            ${bashWaitForever}
          '';
          ExecStop = systemdExecWrapper ''
            ${cleanupScript}
            screen -XS ${sessionName} quit
          '';
        }
        // extraServiceConfig;
      };
    };
  mkWrappedScreenService =
    {
      sessionName,
      username,
      scriptDirName,
      script,
      wantedBy ? [ "multi-user.target" ],
      requires ? [ "network-online.target" ],
      after ? [ ],
      cleanupScript ? "",
      extraServiceConfig ? { },
    }:
    mkScreenService {
      inherit
        sessionName
        username
        wantedBy
        requires
        after
        extraServiceConfig
        ;
      script = pkgs.writeScript "wrapped-service-script" ''
        ${bashEnsureInternet}
        cd ~ && mkdir -m 750 -p screen-runs/${scriptDirName}; cd screen-runs/${scriptDirName};
        clear
        date
        pwd

        ${script}

        ${bashWaitForever}
      '';
    };
  # GUI autostart via the XDG autostart spec (the mechanism KDE Plasma uses).
  #
  # Why not a systemd system service (what this replaced): the old
  # mkGuiAutostartService hooked "graphical.target", which is a *system* target
  # reached at the login screen - before any user session exists - and then
  # tried to reconstruct a session environment with `systemctl --user
  # show-environment`. On a multi-user machine there is no "the" session, so it
  # started as root against a session that wasn't there and retried forever.
  #
  # A .desktop in /etc/xdg/autostart is launched by KDE *inside* the session, so
  # DISPLAY / WAYLAND_DISPLAY / DBUS_SESSION_BUS_ADDRESS / XDG_RUNTIME_DIR and
  # audio are inherited correctly - no environment reconstruction at all - and
  # it runs independently for every user who logs in (and only while they are
  # logged in). Users can still switch an entry off in System Settings ->
  # Autostart, which writes ~/.config/autostart/<name>.desktop and overrides
  # this system-wide file.
  #
  # A .desktop file cannot carry the orchestration (Exec does not expand shell
  # variables), so it points at a generated launcher that holds all of it.
  mkGuiAppAutostart =
    {
      appName,
      repoName,
      repoUrl,
      flakeAttr ? "desktop",
      # Extra shell lines evaluated in the session before the app starts, e.g.
      # additional env vars for apps that need them.
      envScript ? "",
      # Repo-relative paths whose executables start_desktop_app.sh runs on its
      # "unchanged" branch, e.g. [ "Foo/bin/Release/net10.0/Foo.dll" ]. Used to
      # infer that a build actually happened, so the apps can stay dumb. Empty
      # means every launch rebuilds (correct, just slower).
      artifacts ? [ ],
      # Explicit script, for autostarts that do not use the git+flake pattern
      # at all (conky's duplicate culler, pipewire-pulse).
      launcherScript ? null,
      # Build the app with this shell command instead of `nix develop` + a
      # repo-side start script. For expensive apps (a Tauri build takes minutes)
      # set this to something that produces a stable path, and give
      # `launchCommand` below to run it. The command runs ONLY when the revision
      # changed, and its output is what gets launched, so a plain login costs
      # nothing.
      #
      #   buildCommand = ''
      #     exec "$nix_bin" build "$repo#default" --out-link "$build_out"
      #   '';
      buildCommand ? null,
      # What to run once built (the app's own command). Defaults to the
      # repo-side start_desktop_app.sh inside the flake dev shell.
      launchCommand ? null,
      # Restart after a non-zero exit, e.g. for a long-running app that should
      # survive a crash. Keep false for anything that exits on purpose.
      restartOnExit ? false,
      # Run the app inside a `screen` session so its stdout/stderr are visible
      # afterwards: `screen -r gui-<app>` to attach, or read the logfile. Opt-in
      # because it gives the app a pty, which can change how a GUI app behaves.
      screenWrap ? false,
    }:
    let
      git = "${pkgs.git}/bin/git";
      # nix uses the stable channel like the rest of the system; the version in
      # the launcher script's name is cosmetic, its content decides the hash.
      nixPackage = pkgs.nixVersions.stable;
      # What actually launches the app. With `launchCommand` given, that string
      # is used verbatim (typically running the built artefact). Otherwise it is
      # the repo-side start script inside the flake dev shell, and the inner
      # `bash -c` argument is escaped so it survives interpolation into the
      # screen command line below.
      appCommand =
        if launchCommand != null then
          launchCommand
        else
          ''"$nix_bin" develop --profile "$profile" "$repo#${flakeAttr}" -c bash -c ${lib.escapeShellArg "cd \"$NIXOS_JNCCD_GUI_APP_REPO\" && bash start_desktop_app.sh"}'';
      # Runs instead of `appCommand` when this revision still needs building.
      # Falls back to appCommand so the two-mode split only exists when asked
      # for: with no buildCommand the "build" IS running the app (what the .NET
      # apps do).
      #
      # A buildCommand is expected to record its own success by writing the
      # revision it built to "$state_dir/built". That is the honest signal: with
      # `nix build` the exit status is meaningful (unlike the .NET apps' start
      # script, which returns 0 whether or not the compile worked). If the marker
      # is never written, the revision is treated as not-built and the previous
      # build keeps running rather than being lost.
      buildStep =
        if buildCommand != null then
          ''if ! (
              ${buildCommand}
            ); then
              echo "gui-autostart ${appName}: build failed; keeping the previous build" >&2
            fi''
        else
          appCommand;
      # screen keeps its own scrollback, so attaching shows what already
      # happened. Detached (-dmS) on purpose: a KDE autostart entry is not
      # guaranteed a controlling tty, and foreground screen fails with
      # "Must be connected to a terminal" in that case. Because it is detached,
      # the launcher's exit status is screen's, not the app's, so this is
      # opt-in and incompatible with restartOnExit.
      appInvocation =
        if screenWrap then
          ''"${pkgs.screen}/bin/screen" -L \
              -Logfile "$state_dir/app.log" \
              -dmS "gui-${appName}-$(id -un)-''${XDG_SESSION_ID:-nosession}" \
              bash -c ${lib.escapeShellArg appCommand}''
        else
          # Subshell: if launchCommand uses `exec`, it replaces only the
          # subshell, so the exit status is still observable here (an `exec` at
          # this level would replace the launcher and skip the bookkeeping).
          "( ${appCommand} )";
      restartClause =
        if restartOnExit then
          ''echo "gui-autostart ${appName}: exited $rc, restarting in 5s" >&2; sleep 5''
        else
          ''echo "gui-autostart ${appName}: exited $rc" >&2; exit "$rc"'';
      launcher =
        if launcherScript != null then
          pkgs.writeShellScript "gui-autostart-${appName}" launcherScript
        else
          pkgs.writeShellScript "gui-autostart-${appName}" ''
            set -uo pipefail

            # $HOME is the logged-in user's home, so the clone, the profile and
            # the state are per-user automatically - no username plumbing.
            repo="$HOME/.local/share/gui-apps/${repoName}"
            profile="$HOME/.nix-profiles/${appName}"
            # Per-app state: build markers and (for buildCommand apps) the built
            # output, which `launchCommand` refers to as "$build_out".
            state_dir="$HOME/.local/state/gui-autostart/${appName}"
            build_out="$state_dir/current"
            mkdir -p "$(dirname "$repo")" "$(dirname "$profile")" "$state_dir"

            # Keep a log of the launcher's own work - the revision decision, the
            # git pull, submodule fetch. Without it a failed pull is invisible,
            # which is exactly the kind of "nothing happened" this whole file
            # keeps running into. The app's own output is not here: see the
            # screenWrap option for that.
            exec >>"$state_dir/launcher.log" 2>&1
            echo "--- $(date -Is) gui-autostart ${appName} ---"

            # screenWrap runs the app detached, so its exit status is never
            # observed and restartOnExit could not do anything. This cannot be a
            # module assertion: this function's return value IS the
            # environment.etc attrset, so there is nowhere to put one.
            ${lib.optionalString (screenWrap && restartOnExit) ''
              echo "gui-autostart ${appName}: screenWrap and restartOnExit are mutually exclusive (the detached app's exit status is not observable); not starting" >&2
              exit 1
            ''}

            # At most one instance per graphical session.
            #
            # The lock is scoped by XDG_SESSION_ID, not just the user: a
            # user-global lock survives logout when the app outlives the
            # session, and the next login would then be blocked forever with no
            # explanation. A per-session lock also means KDE's "restore last
            # session" cannot double-launch: whichever of (restored app,
            # autostart entry) comes second finds the lock held and stands
            # down.
            #
            # This must say so out loud - "nothing happened" is what a silently
            # handled duplicate looks like, and that is indistinguishable from a
            # broken launcher.
            if command -v flock >/dev/null 2>&1 && [ -n "''${XDG_RUNTIME_DIR:-}" ]; then
              lock="$XDG_RUNTIME_DIR/gui-autostart-${appName}-''${XDG_SESSION_ID:-nosession}.lock"
              exec 9>"$lock"
              if ! flock -n 9; then
                echo "gui-autostart ${appName}: already running in this session, not starting a second copy"
                exit 0
              fi
            fi

            # nix may not be on a session's PATH; find the binary, don't assume.
            nix_bin="$(command -v nix || true)"
            if [ -z "$nix_bin" ]; then
              PATH="${nixPackage}/bin:$PATH"
              nix_bin="$(command -v nix || true)"
            fi
            if [ -z "$nix_bin" ]; then
              echo "gui-autostart ${appName}: nix not found on PATH" >&2
              exit 1
            fi

            if [ ! -d "$repo/.git" ]; then
              ${git} clone ${repoUrl} "$repo" || exit 1
            fi

            # "Changed" has to mean "changed since the last successful build",
            # which cannot be decided inside one run: on a fresh clone HEAD
            # before and after the pull are trivially identical, and treating
            # that as "unchanged" makes the app try to run a binary that was
            # never built (it dies with "dotnet ... does not exist").
            #
            # Exit status cannot tell us a build succeeded: start_desktop_app.sh
            # returns 0 both when the .NET build fails and when the user simply
            # closes the window. And the apps are deliberately dumb, so we infer
            # it from the artifact instead: start_desktop_app.sh only ever runs
            # `./bin/Release/.../X.dll` on the UNCHANGED path, so allow that path
            # only when the artifact exists and is newer than the last build
            # marker. A failed build never produces a fresh artifact, so the
            # next launch rebuilds. Set `artifacts` to the path(s) the app
            # actually executes; empty means "always rebuild".
            #
            # Several app repos have a git@github.com: submodule (music-player's
            # Tmds.DBus, for one). With no key that blocks on the host-key /
            # auth prompt, which nobody can answer during autostart. Rewrite to
            # HTTPS (public repos need no credentials) and make ssh fail fast
            # instead of prompting.
            export GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new"
            ${git} config --global --replace-all \
              url."https://github.com/".insteadOf "git@github.com:" || true

            ${git} -C "$repo" reset --hard 2>/dev/null || true
            ${git} -C "$repo" pull --ff-only 2>/dev/null \
              || echo "gui-autostart ${appName}: pull failed, using local revision" >&2
            # Keep the linked submodule revisions; never --remote.
            ${git} -C "$repo" submodule update --init --recursive --force 2>/dev/null || true
            now="$(${git} -C "$repo" rev-parse HEAD 2>/dev/null || echo "")"

            ${envScript}

            # Decide whether this revision still needs building, then run.
            #
            # The artifact is a FALLBACK, not proof of anything. It is the only
            # thing that says "there is something to start", so:
            #
            #   no artifact            -> must build (this is the bug where a
            #                             fresh clone fast-pathed into a binary
            #                             that was never built)
            #   artifact + last build
            #     == this revision     -> run it (the normal fast path)
            #   artifact + last build
            #     != this revision,
            #     already attempted    -> a newer revision failed to build; run
            #                             the previously built one rather than
            #                             retrying the broken revision forever
            #
            # The attempt is recorded BEFORE building, so a revision that fails
            # is attempted once per commit, not on every login. Do NOT delete
            # artifacts to "prove" a build succeeded - that turns a recoverable
            # failure into a permanent one. Do NOT use artifact timestamps
            # either: a build can finish in the same second as the marker write
            # and `-ot` then reports "stale" forever.
            #
            # Markers live under state_dir (per app) rather than inside the
            # repo, so `git reset --hard` / an agent editing the checkout cannot
            # disturb them.
            needs_build=0
            ${
              if artifacts == [ ] then
                ''
                  # No artifact declared, so nothing can tell a successful build
                  # from a failed one: always build.
                  needs_build=1
                ''
              else
                ''
                  artifacts_ok=1
                  for a in ${lib.concatStringsSep " " (map (a: "\"$repo/${a}\"") artifacts)}; do
                    if [ ! -e "$a" ]; then
                      artifacts_ok=0
                      break
                    fi
                  done

                  # A buildCommand app records the revision it successfully
                  # built here; the other apps have no build step and fall back
                  # to last-build, which the run loop writes below.
                  last_build="$(cat "$state_dir/built" 2>/dev/null || echo "")"
                  [ -n "$last_build" ] || last_build="$(cat "$state_dir/last-build" 2>/dev/null || echo "")"
                  attempted="$(cat "$state_dir/build-attempt" 2>/dev/null || echo "")"

                  if [ "''${artifacts_ok}" -eq 1 ]; then
                    if [ -n "$now" ] && [ "$last_build" = "$now" ]; then
                      echo "gui-autostart ${appName}: revision $now is built, running it"
                    elif [ -n "$now" ] && [ "$attempted" = "$now" ]; then
                      # Already attempted and did not mark itself built, so the
                      # attempt failed: run the newest artifact instead of
                      # retrying the broken revision on every login.
                      echo "gui-autostart ${appName}: revision $now did not build, running the last working build"
                    else
                      needs_build=1
                    fi
                  else
                    needs_build=1
                    echo "gui-autostart ${appName}: nothing built yet"
                  fi
                ''
            }

            if [ "$needs_build" -eq 1 ]; then
              # Record the attempt BEFORE building so a failure is not retried
              # every login.
              [ -n "$now" ] && printf '%s\n' "$now" > "$state_dir/build-attempt"
              # The .NET apps need this flag to tell their start script to do a
              # full build rather than run the existing output.
              unset NIXOS_JNCCD_GUI_STARTER_UNCHANGED
              echo "gui-autostart ${appName}: building revision $now"
              ${buildStep}
            else
              # Tell start_desktop_app.sh to skip its build and run the output.
              export NIXOS_JNCCD_GUI_STARTER_UNCHANGED=1
            fi

            # Positional args do NOT survive `nix develop -c bash -c ... _ "$x"`
            # (verified: $1 arrives empty), so pass the path via the environment.
            export NIXOS_JNCCD_GUI_APP_REPO="$repo"
            # The app command is a child process and, with screenWrap, a child of
            # a completely separate screen process. Shell variables that are not
            # exported do not exist there, which turns the whole command into an
            # empty string and yields "bash: line 1: : command not found".
            export nix_bin profile repo state_dir
            while :; do
              ${appInvocation}
              rc=$?
              ${
                if buildCommand != null then
                  ''
                    # A buildCommand app records success in "$state_dir/built"
                    # itself (its build step is the only thing that can tell a
                    # successful build from a failed one).
                  ''
                else
                  ''
                    # No separate build step here, so a clean run is what marks
                    # this revision built; a failure leaves needs_build set for
                    # the next launch.
                    if [ "$rc" -eq 0 ] && [ "$needs_build" -eq 1 ]; then
                      [ -n "$now" ] && printf '%s\n' "$now" > "$state_dir/last-build"
                    fi
                  ''
              }
              [ "$rc" -eq 0 ] && exit 0
              ${restartClause}
            done
          '';
    in
    {
      # Returns the files to put in environment.etc, so call sites read
      #   environment.etc = lib.custom.mkGuiAppAutostart { ... };
      "xdg/autostart/${appName}.desktop".source = pkgs.writeText "autostart-${appName}.desktop" ''
        [Desktop Entry]
        Type=Application
        Name=${appName}
        Comment=Autostart ${appName} in the desktop session
        Exec=${launcher}
        Terminal=false
        # KDE only: the user runs Plasma, and this keeps entries from appearing
        # in (and being launched by) other XDG autostart implementations.
        OnlyShowIn=KDE;
        # Start after the panel is up rather than racing session bring-up.
        X-KDE-autostart-after=panel
      '';
    };

  # Autostart a plain command in the desktop session, for things that are not a
  # git repo built through a flake dev shell (e.g. the dsh web UI for the
  # sandbox user). Same mechanism and guarantees as mkGuiAppAutostart: launched
  # by KDE inside the session, per-session single instance, and inert for users
  # who never log into a desktop.
  #
  # `shellCommand` is used both to run the command and to locate its binary for
  # the pre-flight check, so pass a simple `prog [args]` string.
  mkGuiSessionAutostart =
    {
      appName,
      shellCommand,
      # Restrict to a single account. This needs an explicit guard rather than
      # Home Manager plumbing, because /etc/xdg/autostart is global - without it
      # the command would start for every desktop user.
      onlyUser ? null,
      description ? "Autostart ${appName} in the desktop session",
    }:
    let
      prog = builtins.head (lib.splitString " " shellCommand);
      launcher = pkgs.writeShellScript "gui-autostart-${appName}" ''
        set -uo pipefail

        ${lib.optionalString (onlyUser != null) ''
          if [ "$(id -un)" != "${onlyUser}" ]; then
            exit 0
          fi
        ''}
        # At most one per graphical session; see mkGuiAppAutostart for why the
        # lock is scoped by XDG_SESSION_ID and why the refusal is announced.
        if command -v flock >/dev/null 2>&1 && [ -n "''${XDG_RUNTIME_DIR:-}" ]; then
          lock="$XDG_RUNTIME_DIR/gui-autostart-${appName}-''${XDG_SESSION_ID:-nosession}.lock"
          exec 9>"$lock"
          if ! flock -n 9; then
            echo "gui-autostart ${appName}: already running in this session, not starting a second copy"
            exit 0
          fi
        fi

        # This entry lives in /etc, so it cannot be gated on a NixOS option;
        # report a missing binary rather than dying silently inside KDE.
        if ! command -v ${prog} >/dev/null 2>&1; then
          echo "gui-autostart ${appName}: '${prog}' not found on PATH, not starting" >&2
          exit 0
        fi

        exec ${shellCommand}
      '';
    in
    {
      "xdg/autostart/${appName}.desktop".source = pkgs.writeText "autostart-${appName}.desktop" ''
        [Desktop Entry]
        Type=Application
        Name=${appName}
        Comment=${description}
        Exec=${launcher}
        Terminal=false
        OnlyShowIn=KDE;
        X-KDE-autostart-after=panel
      '';
    };

  mkOnTagUpdatingGitBasedService =
    {
      serviceName,
      repoName,
      repoUrl,
      serviceUser,
      defineEnvVarsScript,
    }:
    mkWrappedScreenService {
      sessionName = serviceName;
      username = serviceUser;
      scriptDirName = serviceName;
      script = pkgs.writeScript "script" ''
        git clone ${repoUrl} || true
        ${scriptForceRefreshGitRepo "./${repoName}"}

        ${defineEnvVarsScript}

        while true; do
          nix develop ./${repoName}#service -c bash ${pkgs.writeScript "script" ''
            cd ${repoName}
            bash start_service.sh
          ''}
          
          ${scriptForceRefreshGitRepo "./${repoName}"}
        done
      '';
    }
    // mkWrappedScreenService {
      sessionName = "${serviceName}-updater";
      username = serviceUser;
      scriptDirName = "${serviceName}-updater";
      script = pkgs.writeScript "script" ''
        sleep 60
        cd ../${serviceName}/${repoName}

        while true; do
          (git reset --hard && git fetch --tags) || (echo "Error fetching updates!" && sleep 120 && continue)

          LOCAL_TAG=$(git describe --tags --abbrev=0 2>/dev/null)
          REMOTE_TAG=$(git describe --tags --abbrev=0 origin 2>/dev/null)

          if [ "$LOCAL_TAG" != "$REMOTE_TAG" ]; then
            echo "Local $LOCAL_TAG / Remote $REMOTE_TAG"
            echo "$(date): New tag(s) available. Sending Ctrl-C to ${serviceName}."
            screen -S "${serviceName}" -X stuff $'\003'
          else
            echo "$(date): No new tag(s)."
          fi

          sleep 120
        done
      '';
    };
  mkUpdatingContainerService =
    {
      screenSessionName,
      serviceName,
      imageName,
      serviceUser,
      defineEnvVarsScript,
      envVarsToPass,
    }:
    mkWrappedScreenService {
      sessionName = screenSessionName;
      username = serviceUser;
      scriptDirName = serviceName;
      script = pkgs.writeScript "script" ''
        ${defineEnvVarsScript}
        while true; do
          docker pull ${imageName}
          docker run -i --restart=always ${
            builtins.concatStringsSep " " (
              lib.concatMap (x: [
                "-e"
                x
              ]) envVarsToPass
            )
          } --replace --name ${serviceName} ${imageName}
        done
      '';
      cleanupScript = ''
        docker stop ${serviceName} || true
        docker rm ${serviceName} || true
      '';
    }
    // mkWrappedScreenService {
      sessionName = "${screenSessionName}-updater";
      username = serviceUser;
      scriptDirName = "${serviceName}-updater";
      script = pkgs.writeScript "script" ''
        old_digest=$(docker inspect --format='{{index .RepoDigests 0}}' ${imageName} 2>/dev/null || echo "")
        while true; do
          docker pull ${imageName} || (echo "Error fetching updates!" && sleep 120 && continue)
          new_digest=$(docker inspect --format='{{index .RepoDigests 0}}' ${imageName})

          if [ "$old_digest" != "$new_digest" ]; then
              echo "New image version detected: $new_digest"
              screen -S ${screenSessionName} -X stuff $'\003'
              old_digest=$new_digest
          else
              echo "No update found."
          fi
          sleep 120
        done
      '';
    };
  mkOnCommitUpdatingNodeWebsiteModule =
    {
      websiteName,
      websiteUrl,
      repoName,
      repoUrl,
      serviceUser,
      buildServiceName,
      firewallPorts,
      isNginxDefault ? false,
    }:
    {
      # - Firewall -
      networking.firewall.allowedTCPPorts = firewallPorts;

      # - Nginx -
      services.nginx = {
        enable = true;

        # Certs go here: /var/lib/acme/[domain]/
        virtualHosts."${websiteUrl}" = {
          default = isNginxDefault;
          addSSL = true;
          enableACME = true;
          root = "/etc/www/${websiteName}/";
        };
      };

      # - Service -
      systemd.services =
        mkWrappedScreenService {
          sessionName = buildServiceName;
          username = serviceUser;
          scriptDirName = buildServiceName;
          script = pkgs.writeScript "website-build-script" ''
            build_site() {
              echo "Rebuilding site..."
              nix develop .#service -c bash -c "npm run build"
              rm -r /etc/www/${websiteName}/*
              cp -r dist/* /etc/www/${websiteName}/
            }

            echo "Startup..."
            git clone ${repoUrl} || echo "Using existing repo"
            cd ${repoName}

            git fetch origin
            if [ $(git rev-list HEAD...origin/main --count) -gt 0 ]; then # This assumes that the default branch is main which is kinda shit but whatever
              echo "Found new commits."
              git pull
              build_site
            else
              echo "No new commits on the remote branch."
            fi

            while true; do
              read -p "Press enter to rebuild"
              git pull

              build_site
            done
          '';
        }
        // mkWrappedScreenService {
          sessionName = "build-${websiteName}-trigger";
          username = serviceUser;
          scriptDirName = "build-${websiteName}-trigger";
          script = pkgs.writeScript "script" ''
            sleep 60
            cd ../${buildServiceName}/${repoName}

            while true; do
              (git reset --hard && git fetch) || (echo "Error fetching updates!" && sleep 120 && continue)

              LOCAL=$(git rev-parse @)
              REMOTE=$(git rev-parse @{u})
              BASE=$(git merge-base @ @{u})

              if [ "$LOCAL" = "$BASE" ] && [ "$REMOTE" != "$BASE" ]; then
                echo "Base $BASE / Local $LOCAL / Remote $REMOTE"
                echo "$(date): New commit(s) available. Sending enter to ${buildServiceName}."
                screen -S "${buildServiceName}" -X stuff $'\n'
              else
                echo "$(date): No new commit(s)."
              fi

              sleep 120
            done
          '';
        };
      environment.etc."www/${websiteName}/.mkdir" = {
        text = "create";
      };
      systemd.tmpfiles.rules = [ "d /etc/www/${websiteName}/ 0770 ${serviceUser} nginx" ];
    };
  mkNasMountService =
    {
      shareFolderName,
      remoteServerName,
      remoteUser,
      remotePassFile,
      localMountUser,
    }:
    let
      mountPoint = "/mnt/nas/${shareFolderName}";
      remoteShare = "//${remoteServerName}/${shareFolderName}";
    in
    mkWrappedScreenService rec {
      sessionName = "mount-nas-${shareFolderName}";
      username = "root";
      scriptDirName = "${sessionName}";
      script = pkgs.writeScript "script" ''
        echo ${remoteShare}
        sudo mkdir -p ${mountPoint}
        sudo mount -t cifs ${remoteShare} ${mountPoint} -o username=${remoteUser},password=$(cat ${remotePassFile}),uid=$(id ${localMountUser} -u),gid=$(id ${localMountUser} -g),dir_mode=0770,file_mode=0660
      '';
      cleanupScript = pkgs.writeScript "cleanup-script" "sudo umount ${mountPoint}";
    };
  mkNasMountModule =
    {
      inputs,
      lib,
      config,
      globalArgs,
      folderName,
      secretsFile,
      mountUser,
    }:
    {
      sops.secrets."nas/${folderName}/user" = {
        sopsFile = "${inputs.self}/secrets/${secretsFile}";
        owner = "root";
      };
      sops.secrets."nas/${folderName}/pass" = {
        sopsFile = "${inputs.self}/secrets/${secretsFile}";
        owner = "root";
      };
      sops.secrets."nas/${folderName}/serverName" = {
        sopsFile = "${inputs.self}/secrets/${secretsFile}";
        owner = "root";
      };

      environment.systemPackages = with pkgs; [ cifs-utils ];

      systemd.services = lib.custom.mkNasMountService {
        shareFolderName = "${folderName}";
        remoteServerName = "$(cat ${config.sops.secrets."nas/${folderName}/serverName".path})";
        remoteUser = "$(cat ${config.sops.secrets."nas/${folderName}/user".path})";
        remotePassFile = config.sops.secrets."nas/${folderName}/pass".path;
        localMountUser = mountUser;
      };
    };
}
