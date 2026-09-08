{
  config,
  lib,
  pkgs,
  globalArgs,
  homeUser,
  ...
}:
let
  isMainUser = homeUser.name == globalArgs.mainUser.name;
  substitute =
    text:
    builtins.replaceStrings [
      "@MAIN_USER@"
      "@SANDBOX_USER@"
      "@NIXOS_CONFIG_REPO_URL@"
      "@REAL_REPO@"
      "@SANDBOX_DIR@"
    ] [
      globalArgs.mainUser.name
      globalArgs.sandboxUser.name
      globalArgs.nixosConfigRepoUrl
      globalArgs.nixosConfigPath
      globalArgs.sandboxConfigPath
    ] text;
in
lib.mkIf isMainUser {
  # Workflow helpers for the AI sandbox review/apply loop, installed as
  # ~/ai-sandbox/prep and ~/ai-sandbox/apply. Only the main user gets them
  # (its home is 0700), so the sandbox user cannot modify them.
  #
  # The sandbox ACCOUNT itself is defined in globalArgs.baseUsers (NixOS-side,
  # so it exists on every host - home-manager modules cannot create users).
  # Its login password is set imperatively once (`sudo passwd sandbox`); with
  # users.mutableUsers at its default that password survives rebuilds, so no
  # sandbox-specific NixOS module is needed anymore.

  home.file."ai-sandbox/prep" = {
    text = substitute (builtins.readFile ./scripts/prep.sh);
    executable = true;
  };
  home.file."ai-sandbox/apply" = {
    text = substitute (builtins.readFile ./scripts/apply.sh);
    executable = true;
  };
}
