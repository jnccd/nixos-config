{ pkgs, lib, ... }:
with (import ./base.nix { inherit pkgs lib; });
rec {
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
