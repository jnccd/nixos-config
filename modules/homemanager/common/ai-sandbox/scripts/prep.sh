#!/usr/bin/env bash
# prep - (re)create the sandbox user's working copy of a repo from the real
# repo's CURRENT working tree. Installed at ~/ai-sandbox/prep.
#
#   prep                     -> the nixos-config (as before)
#   prep ./git/media-control -> any other repo under your home
#
# Run it at the START of every AI round - the very first time and after each
# apply + test cycle. NO commits are needed between rounds: this script
# snapshots whatever the real repo currently contains (committed changes AND
# uncommitted rounds applied earlier) and makes that the agent's base.
#
# Paths: a path is taken relative to the main user's home (or absolute under it)
# and lands at the SAME relative path under the sandbox user's home, e.g.
#   /home/dobiko/git/media-control -> /home/sandbox/git/media-control
# The sandbox user has no git credentials, so other repos are COPIED rather than
# cloned from a remote, which is exactly why this round-trip exists.
#
# For the nixos-config specifically:
#   The private submodules (secrets/, modules/private/) are never copied - the
#   sandbox copy only contains their empty gitlinks, and the sandbox user has no
#   credentials, so that content never reaches the agent. The sandbox `origin`
#   is set to the public upstream (@NIXOS_CONFIG_REPO_URL@) for reference and
#   fetching only; the apply step never depends on it.
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
#   prep [path] -> AI works -> ~/ai-sandbox/apply [path]
#   -> test -> prep -> ... -> git commit -> git push
set -euo pipefail

MAIN_USER="@MAIN_USER@"
SANDBOX_USER="@SANDBOX_USER@"
REPO_URL="@NIXOS_CONFIG_REPO_URL@"
# The nixos-config: the repo prep/apply work on when given no argument.
NIXOS_CONFIG_DIR="@SANDBOX_DIR@"
NIXOS_CONFIG_REAL="@REAL_REPO@"
CACHE_DIR="/home/${MAIN_USER}/.cache/ai-sandbox"

log() { echo "==> $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

# --- resolve the target repo -------------------------------------------------
[[ $# -le 1 ]] || die "Usage: prep [path-to-repo]"

if [[ $# -eq 0 ]]; then
  REAL_REPO="$NIXOS_CONFIG_REAL"
  SANDBOX_DIR="$NIXOS_CONFIG_DIR"
  IS_NIXOS_CONFIG=1
else
  arg="${1%/}"
  if [[ "$arg" = /* ]]; then
    REAL_REPO="$arg"
  else
    REAL_REPO="/home/${MAIN_USER}/${arg#./}"
  fi
  REAL_REPO="$(readlink -f "$REAL_REPO" 2>/dev/null || echo "$REAL_REPO")"

  # Mirror the path under the sandbox home. Anything outside your home is
  # refused rather than guessed at - the mapping would be meaningless.
  case "$REAL_REPO" in
    "/home/${MAIN_USER}"/*) rel="${REAL_REPO#/home/${MAIN_USER}/}" ;;
    *) die "Path must be inside /home/${MAIN_USER} (got: $arg)" ;;
  esac
  SANDBOX_DIR="/home/${SANDBOX_USER}/${rel}"

  # Passing the nixos-config explicitly must still take the clone path.
  if [[ "$REAL_REPO" == "$NIXOS_CONFIG_REAL" ]]; then
    SANDBOX_DIR="$NIXOS_CONFIG_DIR"
    IS_NIXOS_CONFIG=1
  else
    IS_NIXOS_CONFIG=0
  fi
fi

# State is per repo so several repos can be in flight without clobbering each
# other's base snapshot. The nixos-config keeps the historic flat paths so an
# already-prepared workspace stays valid across this change.
if [[ "$IS_NIXOS_CONFIG" -eq 1 ]]; then
  STATE_DIR="${CACHE_DIR}"
else
  STATE_DIR="${CACHE_DIR}/repos/${SANDBOX_DIR#/home/${SANDBOX_USER}/}"
fi
BASE_DIR="${STATE_DIR}/base"
ANCHOR_FILE="${STATE_DIR}/anchor"

# Present in the real repo, never synced into the sandbox or the base copy.
# Only used for the nixos-config: its private submodule content must not travel.
SYNC_EXCLUDES=(--exclude '/.git/' --exclude '/secrets/' --exclude '/modules/private/')

# A hardlinked inode is shared with the real repo: a recursive `chown`/`chmod`
# here would silently rewrite the real repo's ownership, and a delete would
# destroy real objects. `git clone` defaults to hardlinking on a local clone,
# so this must stay --no-hardlinks; the guard below makes a regression loud
# instead of corrupting the real repo.
assert_no_shared_git() {
  local root="$1" n files
  sudo test -d "$root/.git" \
    || die "internal: no .git at $root (the copy did not produce a repository)."
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

# Record the base as a commit in the sandbox copy - the anchor apply diffs
# against. Only created when the working tree differs from HEAD.
record_base() {
  local root
  root="$1"
  sudo "$GIT_BIN" -C "$root" add -A
  if ! sudo "$GIT_BIN" -C "$root" diff --cached --quiet; then
    sudo "$GIT_BIN" -C "$root" -c user.name=ai-sandbox -c user.email=ai-sandbox@localhost \
      commit -qm "ai-sandbox: base snapshot"
  fi
  sudo "$GIT_BIN" -C "$root" rev-parse HEAD
}

# Keep a main-user-owned content copy of the base for apply's safety check.
# Content only: apply's guard ignores /.git/ on both sides, and copying git
# state into a cache dir is pointless (and would expose the real history to a
# future mistake). Top-level entries are copied individually so .git is skipped
# without needing `rsync --delete`, which would have deleted the destination's
# own .git. Nothing is hardlinked.
snapshot_base() {
  local root
  root="$1"
  mkdir -p "$STATE_DIR"
  sudo rm -rf "$BASE_DIR"
  sudo install -d -o "$(id -u)" -g "$(id -g)" -m 0700 "$BASE_DIR"
  while IFS= read -r -d '' top; do
    if [[ "$(basename "$top")" != ".git" ]]; then
      sudo cp -a --no-preserve=ownership "$top" "$BASE_DIR/"
    fi
  done < <(sudo find "$root" -xdev -mindepth 1 -maxdepth 1 -print0)
  sudo chown -R "$(id -u):$(id -g)" "$BASE_DIR"
}

[[ "$(id -un)" == "$MAIN_USER" ]] || die "Run me as $MAIN_USER (TTY or your own desktop session), not as $(id -un)."
command -v git >/dev/null || die "git not found in PATH."
[[ -d "$REAL_REPO/.git" ]] || die "No real git repo at $REAL_REPO."
getent passwd "$SANDBOX_USER" >/dev/null || die "User '$SANDBOX_USER' does not exist yet - merge this config and rebuild first."

SANDBOX_PARENT="$(dirname "$SANDBOX_DIR")"
# Copy into a hidden temp dir next to the target, then `mv` it into place: the
# swap is atomic and the workspace can never be half-finished.
STAGE="${SANDBOX_PARENT}/.prep-stage"

log "Snapshotting $REAL_REPO into $SANDBOX_DIR"

# Make sure the sandbox home and the parent of the workspace exist (first run).
sudo install -d -o "$SANDBOX_USER" -g "$SANDBOX_USER" -m 0700 "/home/${SANDBOX_USER}"
sudo install -d -o "$SANDBOX_USER" -g "$SANDBOX_USER" -m 0700 "$SANDBOX_PARENT"

sudo rm -rf "$SANDBOX_DIR" "$STAGE"
GIT_BIN="$(command -v git)"

if [[ "$IS_NIXOS_CONFIG" -eq 1 ]]; then
  # 1. Clone the committed history (full git for the agent + diff anchor).
  #    --no-hardlinks is mandatory: a local clone hardlinks objects into the
  #    sandbox .git, sharing inodes with the real repo. Keep it first in the
  #    option list so the safety property is the first thing you read.
  sudo "$GIT_BIN" -c clone.recurseSubmodules=false clone --no-hardlinks --no-recurse-submodules "$REAL_REPO" "$STAGE"
  assert_no_shared_git "$STAGE"
  # 2. Overlay the real repo's CURRENT files, incl. uncommitted rounds. Submodule
  #    content is never copied, and .git is excluded so the clone's git stays.
  sudo rsync -a --delete "${SYNC_EXCLUDES[@]}" "$REAL_REPO/" "$STAGE/"
  assert_no_shared_git "$STAGE"
  # 2b. The excludes above stop rsync from copying the private submodules, but if
  #     either path is a plain directory rather than a gitlink in the real repo,
  #     `git clone` already brought its content. Empty those paths explicitly so
  #     the workspace only ever contains the empty gitlinks the README promises.
  for sub in secrets modules/private; do
    [[ -d "$STAGE/$sub" ]] || continue
    sudo find "$STAGE/$sub" -xdev -mindepth 1 -delete
  done
  # Point origin at the public upstream (reference / fetch only).
  sudo "$GIT_BIN" -C "$STAGE" remote set-url origin "$REPO_URL" || true
else
  # Any other repo: plain copy, never a clone. rsync WITHOUT -H copies file
  # contents, so nothing is shared with the real repo - no hardlink hazard.
  # .git IS copied (do not exclude it!) so the agent keeps history and apply has
  # the base commit to diff against. Excluding it leaves a non-repository and
  # every later git call fails with "not a git repository".
  sudo rsync -a --delete "$REAL_REPO/" "$STAGE/"
  # No credentials in the sandbox and no business pushing anywhere: drop the
  # remote so an accidental `git push` cannot even try.
  sudo "$GIT_BIN" -C "$STAGE" remote remove origin 2>/dev/null || true
fi

anchor="$(record_base "$STAGE")"

# Hardlinked inodes in the stage would make the chown below re-own (or a later
# delete destroy) the real repo's objects. Asserted above for the clone path;
# assert once more right before the ownership handover (covers the copy path).
assert_no_shared_git "$STAGE"

# 3. Base snapshot for apply's safety check, then the anchor that names it.
snapshot_base "$STAGE"
printf '%s\n' "$anchor" > "$ANCHOR_FILE"

# 4. Hand the workspace to the sandbox user. Safe now: nothing shares inodes
#    with the real repo (asserted above), so this chown only touches copies.
sudo mv "$STAGE" "$SANDBOX_DIR"
sudo chown -R "$SANDBOX_USER:$SANDBOX_USER" "$SANDBOX_DIR"
assert_sandbox_owned "$SANDBOX_DIR"

log "Sandbox workspace ready."
echo "  real repo:   $REAL_REPO"
echo "  path:        $SANDBOX_DIR"
echo "  base commit: $anchor"
if [[ "$IS_NIXOS_CONFIG" -eq 1 ]]; then
  echo "  origin:      $REPO_URL (reference only)"
fi
echo
echo "Next: let the agent work inside $SANDBOX_DIR, then run"
echo "  ~/ai-sandbox/apply${1:+ $1}"
echo "to review and copy the changes back into $REAL_REPO."
if [[ "$IS_NIXOS_CONFIG" -eq 1 ]]; then
  echo "(apply with no argument also rebuilds the system.)"
  echo "Do NOT touch the real repo while the agent works - apply will refuse."
fi
