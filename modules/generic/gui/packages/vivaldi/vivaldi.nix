{ config, lib, pkgs, globalArgs, ... }: {
  config = {
    environment.systemPackages = with pkgs;
      (if config.dobikoConf.nonEssentialGuiPkgs.enabled then [
        (vivaldi.overrideAttrs (oldAttrs: {
          vivaldi-ffmpeg-codecs = vivaldi-ffmpeg-codecs;
          postInstall = (oldAttrs.postInstall or "") + ''
            mkdir -p $out/opt/vivaldi/resources/vivaldi/user_files/
            cp ${
              ./Filter_DarkMode.css
            } $out/opt/vivaldi/resources/vivaldi/user_files/
          '';
        }))
        vivaldi-ffmpeg-codecs
      ] else
        [ ]);
  };
}
