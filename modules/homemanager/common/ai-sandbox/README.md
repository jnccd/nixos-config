# AI Agent Sandbox (`sandbox` user + human-approval apply loop)

## Goal

Give an AI agent its own Linux user (`sandbox`) with its own KDE session so it
can develop and *look at* GUI applications, while **every change to the system
stays human-approved**.

The sandbox user is available on all hosts (it is in `globalArgs.baseUsers`).
It is deliberately boring:

- normal user, uid/gid 1001, its own `0700` home, subuid/subgid ranges
- **no** extra groups (no `wheel`, no `networkmanager`, ...)
- **no** ssh keys; it can log into its own KDE session at SDDM after a password
  was set once with `sudo passwd sandbox`
- it cannot read `/home/dobiko` (0700), `/mnt/nas/*` (mounted
  `dobiko:dobiko 0770`), `/run/secrets`, or the private submodules
- like every real user it receives the shared dotfiles via `nix-cpd`

## The working copy

The agent works in `/home/sandbox/git/nixos-config` (mirroring your own
`/home/dobiko/git/nixos-config`). `prep` builds it from a **snapshot of your
real repo's current working tree** - committed history plus whatever is
uncommitted there right now (e.g. rounds applied earlier):

- the agent always starts from your *current* state - local commits you have
  not pushed yet, and applied-but-uncommitted rounds (no commit, no push
  required between rounds)
- the private submodules (`secrets/`, `modules/private/`) are never copied -
  the sandbox copy only contains their empty gitlinks, and the sandbox user has
  no credentials, so their content never reaches the agent
- the agent cannot push (its `origin` points at the public repo, but no
  credentials exist anywhere in the sandbox)
- full git history/diff tooling for the agent

## The loop - when do you run what?

The scripts are installed at `~/ai-sandbox/prep` and `~/ai-sandbox/apply`
(main user only). **No commits are needed between rounds** - you commit once,
when you are happy with the result:

```
        +---------------------------- ~/ai-sandbox/prep -----------------------+
        |   run at the START of every round. Snapshots the real repo's current  |
        |   working tree (committed or not) into /home/sandbox/git/nixos-config,|
        |   records it as the base in ~/.cache/ai-sandbox/{base,anchor}         |
        v                                                                       |
AI works in /home/sandbox/git/nixos-config                                your feedback
        |                                                                       ^
        v                                                                       |
~/ai-sandbox/apply  (separate TTY, review diff, type YES)                       |
  1. refuses if the real repo no longer matches the recorded base snapshot      |
     (i.e. you edited it while the agent worked)                                |
  2. snapshots the sandbox workspace (agent cannot race the review)             |
  3. shows the full git diff vs the base (new files included;                  |
     flake.nix/flake.lock/.gitmodules/dotfiles changes flagged)                 |
  4. applies EXACTLY the reviewed diff via git apply, then runs nix-rb chain    |
        |                                                                       |
        v                                                                       |
you test the new system state                                                   |
        +------------------------------ (then prep again) ----------------------+
```

Concretely:

- **`prep` runs once per round, at the start** - the very first time, and
  before each agent session. It absorbs whatever the real repo currently holds
  (your own manual edits included) into the agent's base.
- **`apply` runs at the end of a round**, after the agent finished editing. It
  applies the diff and rebuilds. It records no state of its own - the base
  snapshot is only refreshed by `prep`, and `apply` refuses to run if the real
  repo changed since the last `prep` (byte-for-byte check against
  `~/.cache/ai-sandbox/base`).
- When you are happy with everything, commit once:
  `git -C /home/dobiko/git/nixos-config add -A && git ... commit && git ... push`

If you edit the real repo *while the agent works*, `apply` refuses with a clear
message instead of silently clobbering your edits - run `prep` again and your
edits become part of the next base.

## First activation

The loop needs the account and scripts to exist, so apply this diff to the real
repo once the normal way:

1. copy the changed files into `/home/dobiko/git/nixos-config`,
2. rebuild once (`nix-rb`) - this creates the `sandbox` account and installs
   `~/ai-sandbox/prep` + `~/ai-sandbox/apply` in your home,
3. give it a login password once:
   `sudo passwd sandbox`
   (NixOS does not manage this password - nothing password-related is declared
   for the sandbox - and with `users.mutableUsers` at its default `true` it
   survives every later rebuild),
4. log into a KDE session as `sandbox` once so Plasma initializes its home,
5. run `~/ai-sandbox/prep` - the loop is ready.

## Manually copying files without breaking the submodules

When the sandbox copy is a *plain directory* (not a git clone), the safe way to
copy it onto the real repo is `rsync` with the git metadata and the submodule
directories excluded - otherwise `--delete` would wipe the real, populated
`secrets/`/`modules/private/` checkouts and clobber the real `.git`:

```bash
rsync -a --delete --dry-run \
  --exclude='/.git/' \
  --exclude='/secrets/' \
  --exclude='/modules/private/' \
  /home/sandbox/git/nixos-config/ /home/dobiko/git/nixos-config/
```

Drop `--dry-run` to apply. Notes:

- the leading `/` anchors the excludes to the top level
- add an exclude for any future submodule path
- never use `cp -a`, `mv`, or `rsync` without those excludes
- this primitive only works if both sides share the same base; the `apply`
  script prefers snapshot + `git apply` because that makes "what you reviewed"
  byte-identical to "what gets applied"

## Security notes / known trade-offs

- **Approving a diff is code review.** Nix config changes become code that runs
  as root at build time and as the main user at activation time. A human
  scanning a large diff is the weakest link. Keep agent sessions scoped, and
  specifically eyeball: `inputs =` in `flake.nix`, `imports =`, `.gitmodules`,
  `copy-dotfiles/`, and `dotfiles/.config/autostart/`.
- The agent can only change the system through this review gate; it cannot
  write to `/home/dobiko` (0700), cannot `sudo` (not in `wheel`), has no ssh
  keys, and has no access to `/mnt/nas/*` (mounted `dobiko:dobiko 0770`). This
  relies on `/home/dobiko` really being 0700 (see below); if it is `0755` the
  agent can read anything in your home that is not itself 0700.
- **Network access is deliberately open.** The sandbox user can reach the
  internet and DNS; that is required for the agent's work. The boundary is
  filesystem access + the review gate, *not* network isolation. Anything the
  agent can read it can also upload, so keep secrets out of world-readable
  paths inside `/home/dobiko`.
- **The sandbox `.git` never shares inodes with the real `.git`.** `prep` clones
  with `--no-hardlinks` because a default local `git clone` hardlinks objects,
  which made the sandbox copy and the real repository the same files: the
  `chown -R` in `prep` then re-owned the real repo's objects to the sandbox user
  (real repo fails with `unable to open loose object ...: Permission denied` and
  `bad object HEAD`), and a delete in the sandbox could destroy real objects.
  `assert_no_shared_git` in `prep.sh` fails loudly if this ever regresses; do
  not remove `--no-hardlinks`.
- `prep` empties `secrets/` and `modules/private/` in the workspace even if they
  are plain directories rather than gitlinks, so private content never reaches
  the agent regardless of how the real repo is laid out.
- The rebuild is atomic per NixOS; roll back a bad rebuild with
  `sudo nixos-rebuild switch --rollback`.
- **In-sandbox testing is limited.** The sandbox copy has no submodule content,
  and parts of the config read from it (e.g. `${inputs.self}/secrets/*.yaml`,
  `modules/private`), so a full `nixos-rebuild build-vm --flake
  /home/sandbox/git/nixos-config#<host>` will fail on modules that touch those.
  The agent can still lint its edits (`nix-instantiate --parse`), build
  independent derivations, and test GUI apps - but full evaluation happens on
  your approved apply. If you want an eval check before switching, run
  `sudo nixos-rebuild build --flake "$(real repo)?submodules=1"` first - it
  reuses the same build when you switch.
- If you ever expose sshd with password auth, consider denying the sandbox
  user there too (`services.openssh.settings.PasswordAuthentication` or a
  `Match User` block) - on GUI hosts it *has* a password.
