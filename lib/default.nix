{ pkgs, lib, ... }:
{
  userNameToPostgresRoleName = username: lib.replaceStrings [ "-" "." ] [ "_" "_" ] username;

  listAllLocalImportables =
    path:
    builtins.map (f: (path + "/${f}")) (
      builtins.attrNames (
        lib.attrsets.filterAttrs (
          path: _type:
          (_type == "directory") # include directories
          || (
            (path != "default.nix") # ignore default.nix
            && (lib.strings.hasSuffix ".nix" path) # include .nix files
          )
        ) (builtins.readDir path)
      )
    );

  unwrapOverrideSet =
    val: if builtins.isAttrs val && val ? _type && val._type == "override" then val.content else val;
}
// (import ./service.nix { inherit pkgs lib; })
