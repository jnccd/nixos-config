{ pkgs, lib, ... }:
with (import ./base.nix { inherit pkgs lib; });
rec {
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
}
