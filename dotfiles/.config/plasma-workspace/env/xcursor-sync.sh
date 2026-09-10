#!/usr/bin/env sh
# ============================================================================
# xcursor-sync.sh
# Keep XCURSOR_THEME / XCURSOR_SIZE in sync with the desktop's LIVE cursor
# settings, so X11 (XWayland) apps render the same cursor as native Wayland
# surfaces.
#
# WHY THIS EXISTS
#   Under a Wayland session (KDE Plasma, ...) X11 apps run through XWayland and
#   do NOT get the compositor's cursor.  Each X11 client draws its own cursor
#   via libXcursor, which reads $XCURSOR_THEME / $XCURSOR_SIZE (and falls back
#   to X resources / "default" theme / legacy black core-font cursors).
#   When those env vars are unset, clients end up with a small black cursor
#   (e.g. Steam/Chromium, Avalonia windows) while the rest of the desktop shows
#   the theme chosen in System Settings.
#
# WHAT IT DOES (idempotent; run at every login)
#   1. reads the live KDE cursor theme + size from ~/.config/kcminputrc
#      ([Mouse] cursorTheme, [Mouse] cursorSize, default size 24), so changes
#      made in System Settings are picked up automatically,
#   2. multiplies the size by the largest active output scale (same policy
#      KWin uses for XWayland cursors, incl. multi-monitor),
#   3. exports the values into the current session AND rewrites
#      ~/.config/environment.d/20-xcursor.conf for systemd / the next login.
#
# INSTALL (KDE Plasma)
#   Put this file in ~/.config/plasma-workspace/env/
#   Plasma sources every *.sh there at session start, before apps launch.
#   On this NixOS setup it is provisioned from the dotfiles repo:
#     dotfiles/.config/plasma-workspace/env/xcursor-sync.sh
#
#   CAREFUL: this hook runs BEFORE kwin_wayland creates the Wayland socket.
#   Never run a Qt GUI tool here unconditionally - kscreen-doctor would abort
#   with a Qt "no platform plugin" fatal and dump core on every login. See
#   display_ready() below.
#
# PER-MACHINE OVERRIDES (optional)
#   XCURSOR_THEME        already exported  -> kept as-is
#   XCURSOR_SIZE         already exported  -> kept as-is
#   XCURSOR_SYNC_SCALE   force display scale, e.g. "2" (default: auto-detect)
#   XCURSOR_SYNC_NO_SIZE=1 -> never export XCURSOR_SIZE (trust the
#                             compositor's own X resource instead)
# ============================================================================

cfg_home="${XDG_CONFIG_HOME:-$HOME/.config}"
kcminputrc="$cfg_home/kcminputrc"

# value of `key=` in the [Mouse] section of kcminputrc
kde_key() {
    awk -v k="$1" '
        /^[[:space:]]*\[/ { sec = $0; gsub(/^[[:space:]]*\[|\].*$/, "", sec) }
        sec == "Mouse" && /^[A-Za-z0-9_]+=/ {
            i = index($0, "=")
            if (substr($0, 1, i - 1) == k) {
                v = substr($0, i + 1)
                sub(/[ \t\r]*$/, "", v)
                print v
                exit
            }
        }
    ' "$kcminputrc" 2>/dev/null
}

# Is a Qt GUI app able to open a display *right now*?
# At login this hook is sourced before kwin_wayland creates the Wayland
# socket, so nothing is ready yet; kscreen-doctor would abort (SIGABRT) with a
# Qt platform-plugin fatal. Only query it once a display or socket exists, and
# fall back to the saved kwinoutputconfig.json otherwise.
display_ready() {
    if [ -n "$DISPLAY" ]; then
        return 0
    fi
    runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    if [ -n "$WAYLAND_DISPLAY" ]; then
        [ -S "$runtime/$WAYLAND_DISPLAY" ]
    else
        [ -S "$runtime/wayland-0" ]
    fi
}

# largest active output scale (KWin's policy for XWayland cursor size)
current_scale() {
    s=""
    if display_ready && command -v timeout >/dev/null 2>&1 && command -v kscreen-doctor >/dev/null 2>&1; then
        s=$(timeout 5 kscreen-doctor -o 2>/dev/null \
            | sed 's/\x1b\[[0-9;]*m//g' \
            | sed -n 's/^[[:space:]]*Scale:[[:space:]]*\([0-9][0-9.]*\).*/\1/p' \
            | sort -nr | head -n 1)
    fi
    if [ -z "$s" ] && [ -r "$cfg_home/kwinoutputconfig.json" ]; then
        s=$(sed -n 's/.*"scale"[[:space:]]*:[[:space:]]*\([0-9][0-9.]*\).*/\1/p' \
            "$cfg_home/kwinoutputconfig.json" | sort -nr | head -n 1)
    fi
    case "$s" in
        ''|*[!0-9.]*) echo 1 ;;
        *) echo "$s" ;;
    esac
}

# ---------------------------------------------------------------------------
# theme
# ---------------------------------------------------------------------------
theme=""
if [ -n "$XCURSOR_THEME" ]; then
    theme="$XCURSOR_THEME"
elif [ -r "$kcminputrc" ]; then
    theme=$(kde_key cursorTheme)
fi

# ---------------------------------------------------------------------------
# size (logical KDE size * largest output scale)
# ---------------------------------------------------------------------------
size=""
if [ -n "$XCURSOR_SIZE" ]; then
    size="$XCURSOR_SIZE"
elif [ -z "$XCURSOR_SYNC_NO_SIZE" ] && [ -r "$kcminputrc" ]; then
    logical=$(kde_key cursorSize)
    case "$logical" in
        ''|*[!0-9]*) logical=24 ;;   # Plasma default cursor size
    esac
    if [ -n "$XCURSOR_SYNC_SCALE" ]; then
        scale="$XCURSOR_SYNC_SCALE"
    else
        scale=$(current_scale)
    fi
    case "$scale" in
        ''|*[!0-9.]*) scale=1 ;;
    esac
    size=$(awk -v l="$logical" -v s="$scale" 'BEGIN { printf "%d", l * s + 0.5 }')
fi

# ---------------------------------------------------------------------------
# refresh ~/.config/environment.d/20-xcursor.conf (used by systemd at login
# and by non-Plasma sessions)
# ---------------------------------------------------------------------------
if [ -n "$theme" ] || [ -n "$size" ]; then
    out_dir="$cfg_home/environment.d"
    mkdir -p "$out_dir" 2>/dev/null || true
    if [ -d "$out_dir" ]; then
        tmp="$out_dir/20-xcursor.conf.tmp.$$"
        {
            echo "# generated by xcursor-sync.sh"
            echo "# (dotfiles/.config/plasma-workspace/env/xcursor-sync.sh)"
            echo "# regenerated at every login from the live KDE cursor settings"
            [ -n "$theme" ] && echo "XCURSOR_THEME=$theme"
            [ -n "$size" ] && echo "XCURSOR_SIZE=$size"
        } > "$tmp" 2>/dev/null && mv -f "$tmp" "$out_dir/20-xcursor.conf" 2>/dev/null
        rm -f "$tmp" 2>/dev/null
    fi
fi

# ---------------------------------------------------------------------------
# export into the current session (effective when Plasma *sources* this file;
# harmless when it is executed standalone)
# ---------------------------------------------------------------------------
[ -n "$theme" ] && export XCURSOR_THEME="$theme"
[ -n "$size" ] && export XCURSOR_SIZE="$size"
