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
# The sandbox .git NEVER shares inodes with the real .git. A local `git clone`
# hardlinks objects by default, which would make the sandbox copy and the real
# repo the same files: the `chown -R` below would then re-own the real repo's
# objects to the sandbox user (so they become unreadable to you - the real repo
# fails with "unable to open loose object ...: Permission denied" and a
# "bad object HEAD"), and a delete in the sandbox could destroy real objects.
# Hence --no-hardlinks, plus assert_no_shared_git as a hard guard.
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

# A hardlinked inode is shared with the real repo: a recursive `chown`/`chmod`
# here would silently rewrite the real repo's ownership, and a delete would
# destroy real objects. `git clone` defaults to hardlinking on a local clone,
# so this must stay --no-hardlinks; the guard below makes a regression loud
# instead of corrupting the real repo.
assert_no_shared_git() {
  local root="$1" n files
  sudo test -d "$root/.git" \
    || die "internal: no .git at $root (the clone did not produce a repository)."
  files="$(sudo find "$root/.git" -xdev -type f 2>/dev/null | wc -l)"
  n="$(sudo find "$root/.git" -xdev -type f -links +1 2>/dev/null | wc -l)"
  if [[ "$n" -gt 0 ]]; then
    echo "ERROR: $n file(s) under $root/.git share an inode with another file -" >&2
    echo "       almost certainly the REAL repo's .git. Continuing would re-own" >&2
    echo "       (or delete) real git objects." >&2
    sudo find "$root/.git" -xdev -type f -links +1 2>/dev/null | head -n 20 >&2
    die "refusing to touch a .git that shares inodes."
  fi
  local uniq
  uniq="$(sudo find "$root/.git" -xdev -type f -printf '%D:%i\n' 2>/dev/null | sort -u | wc -l)"
  [[ "$uniq" -eq "$files" ]] || die "internal: inode accounting disagrees at $root/.git."
}

# Everything handed to the sandbox must end up owned by the sandbox user, or a
# later `git` run there fails with EACCES. (Before --no-hardlinks, this same
# ownership change was what leaked into the real repo through shared inodes.)
assert_sandbox_owned() {
  local root="$1" uid
  uid="$(id -u "$SANDBOX_USER")"
  [[ -z "$(sudo find "$root/.git" -xdev ! -uid "$uid" -print -quit 2>/dev/null)" ]] \
    || die "internal: something under $root/.git is not owned by $SANDBOX_USER."
}

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
#    --no-hardlinks is mandatory: a local clone hardlinks objects into the
#    sandbox .git, sharing inodes with the real repo. Keep it first in the
#    option list so the safety property is the first thing you read.
sudo "$GIT_BIN" -c clone.recurseSubmodules=false clone --no-hardlinks --no-recurse-submodules "$REAL_REPO" "$CLONE_STAGE"
# Fail loudly if anything is still shared with the real repo before we chown.
assert_no_shared_git "$CLONE_STAGE"
# 2. Overlay the real repo's CURRENT files, incl. uncommitted rounds. Submodule
#    content is never copied, and .git is excluded so the clone's git stays.
sudo rsync -a --delete "${SYNC_EXCLUDES[@]}" "$REAL_REPO/" "$CLONE_STAGE/"
# rsync must not have touched the clone's .git (the excludes protect it), and
# the clone's objects are still not shared with the real repo.
assert_no_shared_git "$CLONE_STAGE"
# 2b. The excludes above stop rsync from copying the private submodules, but if
#     either path is a plain directory rather than a gitlink in the real repo,
#     `git clone` already brought its content. Empty those paths explicitly so
#     the workspace only ever contains the empty gitlinks the README promises.
for sub in secrets modules/private; do
  [[ -d "$CLONE_STAGE/$sub" ]] || continue
  sudo find "$CLONE_STAGE/$sub" -xdev -mindepth 1 -delete
done
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

# Hardlinked inodes in the clone stage would make the chown below re-own (or a
# later delete destroy) the real repo's objects. Asserted after the clone;
# assert once more right before the ownership handover.
assert_no_shared_git "$CLONE_STAGE"

# 4. Keep a main-user-owned content copy of the base for apply's safety check.
#    Content only: the guard in apply.sh ignores /.git/ on both sides, and
#    copying git state into a cache dir is pointless (and would expose the real
#    history to a future mistake). Top-level entries are copied individually so
#    .git is skipped without needing `rsync --delete`, which would have deleted
#    the destination's own .git. Nothing is hardlinked.
mkdir -p "$CACHE_DIR"
sudo rm -rf "$BASE_DIR"
sudo install -d -o "$(id -u)" -g "$(id -g)" -m 0700 "$BASE_DIR"
while IFS= read -r -d '' top; do
  if [[ "$(basename "$top")" != ".git" ]]; then
    sudo cp -a --no-preserve=ownership "$top" "$BASE_DIR/"
  fi
done < <(sudo find "$CLONE_STAGE" -xdev -mindepth 1 -maxdepth 1 -print0)
sudo chown -R "$(id -u):$(id -g)" "$BASE_DIR"
printf '%s\n' "$anchor" > "$ANCHOR_FILE"

# 5. Hand the workspace to the sandbox user. Safe now: the clone shares no
#    inodes with the real repo (asserted in step 1), so this chown only ever
#    touches sandbox-owned copies.
sudo mv "$CLONE_STAGE" "$SANDBOX_DIR"
sudo chown -R "$SANDBOX_USER:$SANDBOX_USER" "$SANDBOX_DIR"
assert_sandbox_owned "$SANDBOX_DIR"

log "Sandbox workspace ready."
echo "  path:        $SANDBOX_DIR"
echo "  base commit: $anchor"
echo "  origin:      $REPO_URL (reference only)"
echo
echo "Next: log into a KDE session as $SANDBOX_USER (SDDM login or KDE 'Switch User')"
echo "and let the agent work inside $SANDBOX_DIR. Everything else in the sandbox"
echo "home is throwaway. Do NOT touch the real repo while the agent works -"
echo "~/ai-sandbox/apply will refuse if it changed."
