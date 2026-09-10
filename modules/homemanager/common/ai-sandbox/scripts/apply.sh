#!/usr/bin/env bash
# apply - review the sandbox user's config edits, apply them to the real repo
# and rebuild the system. Installed at ~/ai-sandbox/apply.
#
# Run this as @MAIN_USER@ from a SEPARATE TTY (e.g. Ctrl+Alt+F3), NOT from
# inside the sandbox's KDE session. The sandbox session cannot see, inject into
# or screenshot that TTY, which makes it a trustworthy approval channel.
#
# What it does:
#   1. verifies the real repo still matches the base snapshot ~/ai-sandbox/prep
#      recorded (~/.cache/ai-sandbox/base) - i.e. nothing changed in the real
#      repo while the agent worked,
#   2. snapshots the sandbox workspace under that main-user-only cache dir -
#      every git query and the final review run on the snapshot, so the agent
#      cannot change what is reviewed/applied behind your back (no TOCTOU),
#   3. shows a full git diff of the agent's changes against the base commit
#      (new files included),
#   4. after you type YES, applies EXACTLY that reviewed diff to the real repo
#      with `git apply` (never touches .git or the submodule checkouts) and runs
#      the same chain as the nix-rb alias.
#
# Iteration: NO commits are needed between rounds. After apply + rebuild, test
# the result, then run ~/ai-sandbox/prep again for the next round. Commit once
# in the real repo when you are happy with everything.
#
# SECURITY: approving this diff means approving Nix code that runs as root
# during the rebuild and as $MAIN_USER during activation. Review it carefully.
# Changes to flake.nix / flake.lock / .gitmodules are flagged below on purpose.
set -euo pipefail

MAIN_USER="@MAIN_USER@"
SANDBOX_DIR="@SANDBOX_DIR@"
REAL_REPO="@REAL_REPO@"
CACHE_DIR="/home/${MAIN_USER}/.cache/ai-sandbox"
ANCHOR_FILE="${CACHE_DIR}/anchor"
BASE_DIR="${CACHE_DIR}/base"
STAGE="${CACHE_DIR}/stage"
PATCH_FILE="${CACHE_DIR}/review.patch"

log() { echo "==> $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

# Excluding the submodule paths keeps anything the agent dropped under
# secrets/ or modules/private/ out of the review diff and out of the patch.
DIFF_SCOPE=(-- . ':(exclude)secrets' ':(exclude)modules/private')

[[ "$(id -un)" == "$MAIN_USER" ]] || die "Run me as $MAIN_USER."
command -v git >/dev/null || die "git not found in PATH."
# The sandbox home is 0700 and owned by the sandbox user, so checking the
# workspace needs root (the snapshot below reads it with sudo anyway).
sudo test -d "$SANDBOX_DIR" || die "No sandbox workspace at $SANDBOX_DIR - run ~/ai-sandbox/prep first."
[[ -d "$REAL_REPO/.git" ]] || die "No real repo at $REAL_REPO."
[[ -f "$ANCHOR_FILE" ]] || die "No anchor found (run ~/ai-sandbox/prep first)."
[[ -d "$BASE_DIR" ]] || die "No base snapshot found (run ~/ai-sandbox/prep first)."
anchor="$(cat "$ANCHOR_FILE")"

# --- 1. guard: the real repo must still equal the prep-time snapshot ----------
# If you edited the real repo while the agent worked, refuse: applying could
# silently clobber your edits. A dry-run rsync with the same anchored path
# excludes prep uses is the check - `diff --exclude` matches base names only
# and cannot express `modules/private`, so it must not be used here.
real_changes="$(rsync -a -c --delete --dry-run --itemize-changes --omit-dir-times \
  --exclude '/.git/' --exclude '/secrets/' --exclude '/modules/private/' \
  "$BASE_DIR/" "$REAL_REPO/" 2>&1 || true)"
if [[ -n "$real_changes" ]]; then
  echo "ERROR: the real repo differs from the base snapshot recorded by prep." >&2
  echo "Changed since prep (first 50 lines):" >&2
  echo "$real_changes" | head -n 50 >&2
  die "Run ~/ai-sandbox/prep again - your edits will become part of the next base."
fi
log "Real repo still matches the base snapshot (anchor ${anchor:0:12})."

# --- 2. snapshot (this is what gets reviewed AND applied) --------------------
log "Snapshotting the sandbox workspace (as root; the sandbox home is 0700)..."
sudo rm -rf "$STAGE"
mkdir -p "$CACHE_DIR"
sudo install -d -o "$MAIN_USER" -g "$MAIN_USER" -m 0700 "$STAGE"
sudo rsync -aH "$SANDBOX_DIR/" "$STAGE/"
sudo chown -R "$(id -u):$(id -g)" "$STAGE"

[[ -d "$STAGE/.git" ]] || die "Sandbox workspace has no .git - run ~/ai-sandbox/prep first."
git -C "$STAGE" cat-file -e "$anchor^{commit}" 2>/dev/null \
  || die "Base commit $anchor is not in the sandbox workspace (history rewritten?) - run ~/ai-sandbox/prep."

# Changes the agent left inside the private submodule paths are ignored by
# design (those dirs are empty gitlinks in the sandbox clone). Warn about them.
sub_hits="$(git -C "$STAGE" status --porcelain 2>/dev/null | grep -E '(^| )((secrets|modules/private)(/|$))' || true)"
if [[ -n "$sub_hits" ]]; then
  echo "NOTE: the agent left changes under secrets/ or modules/private/ (private submodules)." >&2
  echo "Those paths are excluded from review and application:" >&2
  echo "$sub_hits" >&2
fi

# --- 3. review diff ----------------------------------------------------------
log "Computing the diff of the agent's changes vs the base commit..."
git -C "$STAGE" add -N "${DIFF_SCOPE[@]}" >/dev/null 2>&1 || true
git -C "$STAGE" diff "$anchor" "${DIFF_SCOPE[@]}" > "$PATCH_FILE" 2>/dev/null || true

if [[ ! -s "$PATCH_FILE" ]]; then
  if [[ -n "$(git -C "$STAGE" status --porcelain 2>/dev/null || true)" ]]; then
    die "There are changes in the sandbox workspace, but none can be applied via git (only inside private submodule paths?). Run ~/ai-sandbox/prep to reset."
  fi
  echo "No changes to apply."
  exit 0
fi

echo
echo "=== Changes that will be applied to $REAL_REPO ==="
git -C "$STAGE" diff --stat "$anchor" "${DIFF_SCOPE[@]}" || true
echo

# Flag files that deserve extra scrutiny.
while IFS= read -r f; do
  case "$f" in
    .gitmodules | flake.nix | flake.lock | globalArgs.nix)
      echo "!! '$f' changed - inspect very carefully: new inputs / repo metadata are"
      echo "   fetched from the network and executed during the rebuild." ;;
  esac
done < <(git -C "$STAGE" diff --name-only "$anchor" "${DIFF_SCOPE[@]}" 2>/dev/null || true)

if git -C "$STAGE" diff --name-only "$anchor" "${DIFF_SCOPE[@]}" 2>/dev/null | grep -q '^dotfiles/'; then
  echo "!! dotfiles/ changed - these get rsynced into the homes of ALL real users"
  echo "   (including yours) by the rebuild. Check for .config/autostart entries."
fi

echo
echo "Full diff is saved at: $PATCH_FILE"
if [[ -t 0 ]]; then
  read -r -p "Show the full diff now? [y/N] " show
  if [[ "${show,,}" == y* ]]; then
    if command -v less >/dev/null; then less -R "$PATCH_FILE"; else cat "$PATCH_FILE"; fi
  fi
fi

# --- 4. approval -------------------------------------------------------------
echo
read -r -p "Type YES to apply exactly this diff to $REAL_REPO and rebuild the system: " ans
if [[ "$ans" != "YES" ]]; then
  echo "Aborted. Nothing was changed."
  exit 0
fi

# --- 5. apply ----------------------------------------------------------------
log "Applying the reviewed diff with git apply (does not touch .git or submodule checkouts)."
git -C "$REAL_REPO" apply --check "$PATCH_FILE" || die "The patch does not apply cleanly (should not happen while anchored)."
git -C "$REAL_REPO" apply "$PATCH_FILE"

echo
echo "=== Real repo status after apply (changes are uncommitted) ==="
git -C "$REAL_REPO" status --short || true

# --- 6. rebuild (same chain as the nix-rb alias) -----------------------------
echo
echo "Rebuilding - equivalent of:"
echo "  nix-cpd && sudo nixos-rebuild switch --flake $REAL_REPO?submodules=1"
echo "         && home-manager switch -b backup --flake $REAL_REPO?submodules=1 && nix-cpd"
echo "If this fails midway, your changes stay in the repo but are not active"
echo "(roll back with: sudo nixos-rebuild switch --rollback)."
sudo sleep 0
bash "$REAL_REPO/copy-dotfiles/from-repo-to-home.sh"
sudo nixos-rebuild switch --flake "$REAL_REPO?submodules=1"
home-manager switch -b backup --flake "$REAL_REPO?submodules=1"
bash "$REAL_REPO/copy-dotfiles/from-repo-to-home.sh"

echo
echo "Done - the system now runs the reviewed configuration."
echo
echo "Next round (no commit needed):"
echo "  1. test the new system state"
echo "  2. run ~/ai-sandbox/prep, then let the agent do the next round"
echo
echo "Commit once you are happy with everything:"
echo "  git -C $REAL_REPO add -A && git -C $REAL_REPO commit && git -C $REAL_REPO push"
echo "Roll back a bad rebuild with: sudo nixos-rebuild switch --rollback"
