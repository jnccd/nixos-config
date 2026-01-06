rec {
  stateVersion = "25.11";
  homeStateVersion = stateVersion;

  baseUsers = [
    {
      name = "dobiko";
      gitUsername = "jnccd";
      email = "kobidogao@outlook.com";
      isAdmin = true;
      isSystem = false;
      dbAccess = true;
      uid = 1000;
      gid = 1000;
    }
    {
      name = "runner";
      isAdmin = false;
      isSystem = true;
      dbAccess = true;
      uid = 900;
      gid = 900;
    }
  ];
  mainUser = builtins.head (builtins.filter (x: x.isAdmin) baseUsers);
  defaultSystemUser = builtins.head (builtins.filter (x: x.isSystem) baseUsers);
}
