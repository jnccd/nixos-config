# This file is a function returning a derivation (NOT a NixOS module). It
# accepts the package set in any of the common call conventions:
#
#   import ./drv.nix { inherit pkgs; }   -- used by shell.nix and NixOS modules
#   import ./drv.nix pkgs                -- the package set itself (plain `pkgs`)
#   import ./drv.nix { }                 -- fall back to the default nixpkgs
arg:
let
  pkgs =
    if builtins.isAttrs arg && builtins.hasAttr "modulesPath" arg then
      # The NixOS module system is evaluating this file (it was added to
      # `imports`/`modules`). drv.nix is not a module - it is a function that
      # returns a derivation, so fail loudly instead of an infinite recursion.
      throw ''
        drv.nix is not a NixOS module; it is a function that returns a
        derivation, so it must NOT be added to `imports` (or a `modules` list).
        Use it from inside a module instead, e.g.:

          { config, lib, pkgs, ... }:
          let windscribe-gui = import ./drv.nix { inherit pkgs; }; in
          {
            environment.systemPackages = [ windscribe-gui ];
            users.groups.windscribe = { };
            systemd.services.windscribe-helper = {
              description = "Windscribe helper service";
              wantedBy = [ "multi-user.target" ];
              serviceConfig = {
                Type = "simple";
                ExecStart = "''${windscribe-gui}/opt/windscribe/helper";
              };
            };
          }
      ''
    else if builtins.isAttrs arg && builtins.hasAttr "pkgs" arg then
      arg.pkgs
    else if builtins.isAttrs arg && builtins.hasAttr "system" arg then
      # The whole package set (which has a `system` attribute) was passed.
      arg
    else
      import <nixpkgs> { };

  # ---------------------------------------------------------------------------
  # Windscribe Desktop App for Linux
  # ---------------------------------------------------------------------------
  # The upstream project (github.com/Windscribe/Desktop-App) is built with CMake
  # + vcpkg using Windscribe's private registry (ws-vcpkg-registry), which
  # compiles its own Qt, OpenSSL 4.x (SONAME .so.4), a patched curl with TLS
  # Encrypted-Client-Hello and a pinned OpenVPN from source at build time.
  # vcpkg requires unrestricted network access during the build, which Nix
  # sandboxes forbid, so building from source here is not practical.
  #
  # Like the official Arch PKGBUILD in the repo
  # (src/installer/gui/linux/arch_package/PKGBUILD), we therefore repackage the
  # official prebuilt Linux binaries (the amd64 .deb, which contains the same
  # self-contained /opt/windscribe layout the other distro packages ship).
  # The binaries are patched (interpreter + RPATH) so they run against NixOS'
  # glibc and the matching nixpkgs libraries.
  #
  # The URL below is the one Windscribe's own update channel serves for
  # `linux_deb_x64` (https://windscribe.com/install/desktop/linux_deb_x64
  # redirects to deploy.totallyacdn.com/desktop-apps/<version>/...).
  version = "2.23.11";

  src = pkgs.fetchurl {
    url = "https://deploy.totallyacdn.com/desktop-apps/${version}/windscribe_${version}_amd64.deb";
    sha256 = "1vikqf3xwxn3pc6jbmiakrfq0zda8rgm78i1khq9slz7d41ss8lv";
  };

  # Shared libraries the official binaries link against (enumerated with `ldd`
  # on every ELF in the package; they are the runtime deps listed in the .deb's
  # control file, mapped to nixpkgs packages).  The bundled Qt, OpenSSL 4.x
  # (libssl.so.4/libcrypto.so.4), libwsnet.so and the helper binaries
  # (openvpn/ctrld/wstunnel/amneziawg) ship inside the package itself.
  runtimeLibs = with pkgs; [
    acl # libacl.so.1
    brotli # libbrotlidec.so.1
    dbus # libdbus-1.so.3
    fontconfig # libfontconfig.so.1
    freetype # libfreetype.so.6
    glib # libglib-2.0 / libgobject / libgio / libgthread
    harfbuzz # libharfbuzz.so.0
    libcap_ng # libcap-ng.so.0 (windscribeopenvpn)
    libdrm # libdrm.so.2
    libglvnd # libEGL.so.1
    libGL # libGL.so.1
    libnl # libnl-3 / libnl-genl-3 (windscribeopenvpn)
    libx11 # libX11.so.6, libX11-xcb.so.1
    libxcb # libxcb.so.1
    libxcb-cursor # libxcb-cursor.so.0
    libxcb-image # libxcb-image.so.0
    libxcb-keysyms # libxcb-keysyms.so.1
    libxcb-render-util # libxcb-render-util.so.0
    libxcb-util # libxcb-util.so.1
    libxcb-wm # libxcb-icccm.so.4
    libxkbcommon # libxkbcommon.so.0, libxkbcommon-x11.so.0
    pcre2 # libpcre2-8.so.0
    stdenv.cc.cc.lib # libstdc++.so.6
    systemdLibs # libsystemd.so.0
    wayland # libwayland-client / -cursor / -egl
    zstd # libzstd.so.1
  ];

  # Colon-separated search path used by the launcher wrappers (covers any
  # dlopen()'d library in addition to the RPATH-patched direct deps).
  libPath = pkgs.lib.makeLibraryPath runtimeLibs;

  bundledLibDir = "$out/opt/windscribe/lib";

  # The helper's bundled OpenVPN runs its up/down scripts with a deliberately
  # sanitized PATH of /no-such-path (an anti-tamper measure in Windscribe's
  # OpenVPN build), so the stock update-resolv-conf cannot find resolvconf and
  # silently skips switching /etc/resolv.conf to the VPN DNS. On Debian/Ubuntu
  # that script still works because resolvconf lives in /usr/sbin (which the
  # script appends to PATH); on NixOS it is only in the store. We therefore
  # bake an export line with the tool store dirs into the script at build time.
  # The referenced store paths become runtime closure dependencies of $out.
  dnsToolBinPath = pkgs.lib.makeBinPath (with pkgs; [
    coreutils # readlink
    gnugrep
    gnused
    # openresolv MUST precede systemd: both ship a `resolvconf`, and systemd's
    # is a resolvectl shim that cannot handle `resolvconf -a` (which would make
    # the DNS update fail silently).
    openresolv # resolvconf
    gawk # awk (dns-leak-protect)
    util-linux # logger (update-systemd-resolved)
    iptables # iptables-restore (dns-leak-protect)
    nftables
    iproute2 # ip
    systemd # resolvectl / busctl
  ]);
in
pkgs.stdenv.mkDerivation {
  pname = "windscribe-gui";
  inherit version src;

  nativeBuildInputs = [
    pkgs.autoPatchelfHook
    pkgs.patchelf
  ];

  buildInputs = runtimeLibs;

  # autoPatchelfHook rewrites the interpreter and RPATH of every ELF file so
  # its DT_NEEDED libraries resolve, but libraries that are only dlopen()'d at
  # runtime never appear in DT_NEEDED and would be missed - most notably
  # libdbus-1.so.3, which QtDBus loads dynamically. Without it the app cannot
  # reach the session bus and segfaults in the system-tray D-Bus check
  # (QDBusAbstractInterface::callWithArgumentList). Append the full runtime
  # search path (bundled libs + every runtime library) to the RPATH of every
  # patched ELF file, so the raw binary - which the .desktop entry executes -
  # works without the LD_LIBRARY_PATH wrapper.
  appendRunpaths = [ bundledLibDir libPath ];

  # Do NOT let autoPatchelfHook run over the whole tree automatically: it
  # corrupts the packed (section-less) Go helpers windscribeamneziawg and
  # windscribewstunnel when it rewrites their PT_INTERP/adds an RPATH (they
  # then crash inside the dynamic loader at startup). ctrld is a plain static
  # binary that auto-patchelf skips, so it is unaffected. We run auto-patchelf
  # manually in postFixup with those two helpers hidden.
  dontAutoPatchelf = true;

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack
    mkdir -p unpacked
    cd unpacked
    # A .deb is an `ar` archive containing data.tar.xz
    ar x "$src"
    tar xf data.tar.xz
    cd ..
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/opt/windscribe" "$out/bin" "$out/share" "$out/lib/systemd/system" "$out/lib/systemd/system-preset"
    cp -r unpacked/opt/windscribe/. "$out/opt/windscribe/"
    cp -r unpacked/usr/share/. "$out/share/"

    # OpenVPN runs this script with PATH=/no-such-path; give it a usable PATH
    # (see dnsToolBinPath above) so `command -v resolvconf` succeeds.
    ${pkgs.gnused}/bin/sed -i -e '1a export PATH="${dnsToolBinPath}:$PATH"' \
      "$out/opt/windscribe/scripts/update-resolv-conf"

    # Point the desktop entry at the store location of the binary.
    substituteInPlace "$out/share/applications/windscribe.desktop" \
      --replace-fail "/opt/windscribe/Windscribe" "$out/opt/windscribe/Windscribe"

    # Systemd unit for the privileged helper (usable from a NixOS module; the
    # helper additionally needs setuid-root to be fully functional).
    substitute unpacked/usr/lib/systemd/system/windscribe-helper.service \
      "$out/lib/systemd/system/windscribe-helper.service" \
      --replace "/opt/windscribe/helper" "$out/opt/windscribe/helper"
    cp unpacked/usr/lib/systemd/system-preset/69-windscribe-helper.preset \
      "$out/lib/systemd/system-preset/69-windscribe-helper.preset"

    # Launcher wrapper for the GUI (this is what `windscribe-gui` resolves to).
    cat > "$out/bin/windscribe-gui" <<EOF
    #!${pkgs.runtimeShell}
    export LD_LIBRARY_PATH="${bundledLibDir}:${libPath}\''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    exec "$out/opt/windscribe/Windscribe" "\$@"
    EOF
    chmod +x "$out/bin/windscribe-gui"
    ln -s windscribe-gui "$out/bin/windscribe"

    # Wrapper for the CLI.
    cat > "$out/bin/windscribe-cli" <<EOF
    #!${pkgs.runtimeShell}
    export LD_LIBRARY_PATH="${bundledLibDir}:${libPath}\''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    exec "$out/opt/windscribe/windscribe-cli" "\$@"
    EOF
    chmod +x "$out/bin/windscribe-cli"

    runHook postInstall
  '';

  postFixup = ''
    # Run auto-patchelf manually (dontAutoPatchelf is set) with the packed Go
    # helpers hidden, so it patches the dynamic Qt binaries and bundled shared
    # libraries but leaves windscribeamneziawg / windscribewstunnel untouched.
    mkdir -p "$TMPDIR/ws-autopatchelf-hide"
    mv "$out/opt/windscribe/windscribeamneziawg" \
       "$out/opt/windscribe/windscribewstunnel" \
       "$TMPDIR/ws-autopatchelf-hide/"
    autoPatchelf -- "$out"
    mv "$TMPDIR/ws-autopatchelf-hide/"* "$out/opt/windscribe/"
  '';

  meta = with pkgs.lib; {
    description = "Windscribe VPN desktop client (official prebuilt binaries)";
    homepage = "https://www.windscribe.com";
    license = licenses.gpl2Only; # upstream Desktop-App is GPL-2.0-only
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    maintainers = [ ];
  };
}
