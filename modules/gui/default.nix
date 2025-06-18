{ config, lib, pkgs, globalArgs, ... }: {
  imports = lib.custom.listAllLocalImportables ./.;
}
