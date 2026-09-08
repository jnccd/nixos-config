#!/usr/bin/env bash
# prep - (re)create the sandbox user's working copy of the nixos-config from
# the real repo's CURRENT working tree. Installed at ~/ai-sandbox/prep.
#
# Run it at the START of every AI round - the very first time and after each
# apply + rebuild + test cycle. NO commits are needed between rounds: this
# script snapshots whatever the real repo currently contains (committed changes
# AND uncommitted rounds applied earlier) and makes that the agent's base.
#
# The private submodules (secrets/, modules/private/) are never copied - the
# sandbox copy only contains their empty gitlinks, and the sandbox user has no
# credentials, so that content never reaches the agent. The sandbox `origin` is
# set to the public upstream (@NIXOS_CONFIG_REPO_URL@) for reference/fetching
# only; the apply step never depends on it.
#
# Loop (commit only once you are happy with the result):
#   prep -> AI works -> ~/ai-sandbox/apply (review + rebuild)
#   -> test -> prep -> ... -> git commit -> git push
set -euo pipefail

MAIN_USER="@MAIN_USER@"
SANDBOX_USER="@SANDBOX_USER@"
REPO_URL="@NIXOS_CONFIG_REPO_URL@"
SANDBOX_DIR="@SANDBOX_DIR@"
REAL_REPO="@REAL_REPO@"
CACHE_DIR="/home/${MAIN_USER}/.cache/ai-sandbox"

SANDBOX_PARENT="$(dirname "$SANDBOX_DIR")"
# Clone into a hidden temp dir next to the target, then `mv` it into place:
# the swap is atomic and the workspace can never be half-finished.
CLONE_STAGE="${SANDBOX_PARENT}/.clone-stage"
# Pristine main-user-owned copy of the base; apply verifies the real repo
# still matches it before touching anything.
BASE_DIR="${CACHE_DIR}/base"
ANCHOR_FILE="${CACHE_DIR}/anchor"

# Present in the real repo, never synced into the sandbox or the base copy.
SYNC_EXCLUDES=(--exclude '/.git/' --exclude '/secrets/' --exclude '/modules/private/')

log() { echo "==> $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

[[ "$(id -un)" == "$MAIN_USER" ]] || die "Run me as $MAIN_USER (TTY or your own desktop session), not as $(id -un)."
command -v git >/dev/null || die "git not found in PATH."
[[ -d "$REAL_REPO/.git" ]] || die "No real repo at $REAL_REPO."
getent passwd "$SANDBOX_USER" >/dev/null || die "User '$SANDBOX_USER' does not exist yet - merge this config and rebuild first."

log "Snapshotting the real repo's working tree into $SANDBOX_DIR"

# Make sure the sandbox home and the parent of the workspace exist (first run).
sudo install -d -o "$SANDBOX_USER" -g "$SANDBOX_USER" -m 0700 "$SANDBOX_PARENT"

sudo rm -rf "$SANDBOX_DIR" "$CLONE_STAGE"
GIT_BIN="$(command -v git)"

# 1. Clone the committed history (full git for the agent + diff anchor).
sudo "$GIT_BIN" -c clone.recurseSubmodules=false clone --no-recurse-submodules "$REAL_REPO" "$CLONE_STAGE"
# 2. Overlay the real repo's CURRENT files, incl. uncommitted rounds. Submodule
#    content is never copied, and .git is excluded so the clone's git stays.
sudo rsync -a --delete "${SYNC_EXCLUDES[@]}" "$REAL_REPO/" "$CLONE_STAGE/"
# Point origin at the public upstream (reference / fetch only).
sudo "$GIT_BIN" -C "$CLONE_STAGE" remote set-url origin "$REPO_URL" || true
# 3. Record the base as a commit in the sandbox copy - the anchor the apply
#    step diffs against (only created if the overlay differs from HEAD).
sudo "$GIT_BIN" -C "$CLONE_STAGE" add -A
if ! sudo "$GIT_BIN" -C "$CLONE_STAGE" diff --cached --quiet; then
  sudo "$GIT_BIN" -C "$CLONE_STAGE" -c user.name=ai-sandbox -c user.email=ai-sandbox@localhost \
    commit -qm "ai-sandbox: base snapshot"
fi
anchor="$(sudo "$GIT_BIN" -C "$CLONE_STAGE" rev-parse HEAD)"

# 4. Keep a main-user-owned content copy of the base for apply's safety check.
mkdir -p "$CACHE_DIR"
sudo rm -rf "$BASE_DIR"
sudo rsync -a --delete --exclude '/.git/' "$CLONE_STAGE/" "$BASE_DIR/"
sudo chown -R "$(id -u):$(id -g)" "$BASE_DIR"
printf '%s\n' "$anchor" > "$ANCHOR_FILE"

# 5. Hand the workspace to the sandbox user.
sudo mv "$CLONE_STAGE" "$SANDBOX_DIR"
sudo chown -R "$SANDBOX_USER:$SANDBOX_USER" "$SANDBOX_DIR"

log "Sandbox workspace ready."
echo "  path:        $SANDBOX_DIR"
echo "  base commit: $anchor"
echo "  origin:      $REPO_URL (reference only)"
echo
echo "Next: log into a KDE session as $SANDBOX_USER (SDDM login or KDE 'Switch User')"
echo "and let the agent work inside $SANDBOX_DIR. Everything else in the sandbox"
echo "home is throwaway. Do NOT touch the real repo while the agent works -"
echo "~/ai-sandbox/apply will refuse if it changed."
