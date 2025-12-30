{ config, lib, pkgs, globalArgs, inputs, ... }: {
  imports = [ "${inputs.self}/modules/private/common" ];
}
