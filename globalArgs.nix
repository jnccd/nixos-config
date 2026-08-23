rec {
  # --- Version ---
  stateVersion = "26.05";
  homeStateVersion = stateVersion;

  # --- Users ---
  baseUsers = [
    rec {
      name = "dobiko";
      gitUsername = "jnccd";
      email = "kobidogao@outlook.com";
      isAdmin = true;
      isSystem = false;
      dbAccess = true;
      defaultUid = 1000;
      defaultGid = defaultUid;
    }
    rec {
      name = "runner";
      isAdmin = false;
      isSystem = true;
      dbAccess = true;
      defaultUid = 900;
      defaultGid = defaultUid;
    }
  ];
  mainUser = builtins.head (builtins.filter (x: x.isAdmin) baseUsers);
  defaultSystemUser = builtins.head (builtins.filter (x: x.isSystem) baseUsers);

  # --- Paths ---
  nixosConfigPath = "/home/${mainUser.name}/git/nixos-config";
  sopsKeyFile = "/home/${mainUser.name}/.config/sops/age/keys.txt";

  # --- Module options ---
  # I dont use nix options because they are checked in the same top level step that loads modules. So if I want to restrict module loading for ones that aren't active I have to use my own static variables for it.
  # Migrating all options here may make sense for uniformity
  defaultHostArgs = {
    system = "x86_64-linux";

    enableNonEssentialCommonPkgs = true;
    enableDeepseekHarness = false;
  };
}
