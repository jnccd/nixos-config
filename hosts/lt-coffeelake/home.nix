{ config, lib, pkgs, globalArgs, ... }: {
  imports = [
    ../../modules/homemanager/common
    ../../modules/homemanager/gui

  ];
}
