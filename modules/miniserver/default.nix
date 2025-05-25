{ config, lib, pkgs, globalArgs, ... }: {
  imports = [ ./private-module ] ++ lib.custom.importAllLocal ./.;
}
