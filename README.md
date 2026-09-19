# dotfiles

Personal shell, editor, and AI-agent configuration, kept in one place and re-applied with a single script instead of by hand after every container rebuild.

## Contents

| File | Symlinked to |
|---|---|
| `.bashrc` | `~/.bashrc` |
| `.vimrc` | `~/.vimrc` |
| `.tmux.conf` | `~/.tmux.conf` |
| `.gitconfig` | included from `~/.gitconfig` via `include.path` |
| `claude-settings.json` | merged into `~/.claude/settings.json` (see below) |
| `agent-instructions.md` | projected into a target project (see below) |
| `ssh/git_signing.pub` | `~/.ssh/git_signing.pub` |
| `ssh/allowed_signers` | `~/.ssh/allowed_signers` |
| `systemd/ssh-agent.service` | `~/.config/systemd/user/ssh-agent.service` |

`install.sh` does all of the linking. It is idempotent: re-running it just re-points the symlinks, so it is safe to run on every shell start, container create, or rebuild.

## Agent instructions

`agent-instructions.md` is the single source of coding-standard instructions for AI coding agents. `install.sh` projects it into whichever project directory it's told about (`$DOTFILES_PROJECT_ROOT`, see below) in the three formats each tool actually reads:

- `.claude/CLAUDE.md` (Claude Code)
- `.github/copilot-instructions.md` (GitHub Copilot, applies workspace-wide)
- `.cursor/rules/craftsman.mdc` (Cursor; note plain `.md` files are ignored there, hence the frontmatter)

All three are symlinks back to `agent-instructions.md`, so editing the one file updates every tool. If the target project has a `.gitignore`, `install.sh` also appends entries for these paths so the injected files don't get committed to the project's own repo.

## Claude Code settings

Claude Code already layers its settings: `~/.claude/settings.json` (global) sits below a project's own `.claude/settings.json` (shared, tracked) and `.claude/settings.local.json` (personal, gitignored by default), and permission rules merge additively across all three. In practice, permissions you approve interactively during a session land in the *project's* `settings.local.json`, not the global file — that's the right place for them, since they're usually scoped to that project's commands and paths anyway.

`claude-settings.json` here owns only the keys that should be the same everywhere: default model, available models, notification flags. `install.sh` merges it into `~/.claude/settings.json` one-way (dotfiles' values win for those keys) rather than symlinking the whole file, so anything else already sitting in the live file — including a stray global permission Claude wrote there itself — is left alone and never flows back into this repo. If you do want a permission to be global and to survive rebuilds everywhere, add it to `claude-settings.json` deliberately and commit it; don't rely on it accumulating there on its own.

The merge tries `jq` first, then `python3`, since either is enough for the flat, top-level-only merge these keys need. If a global `~/.claude/settings.json` doesn't exist yet, the template is just copied in. If neither `jq` nor `python3` is available on a machine, `install.sh` falls back to overwriting the file outright — you'll see a message saying so, and any local-only keys in that file are lost when it happens.

## SSH commit signing

`.gitconfig` configures SSH signing for all commits and tags. The signing key (`ssh/git_signing.pub`) is tracked here; `install.sh` symlinks it into `~/.ssh/`. The private key (`~/.ssh/git_signing`) is never tracked — it lives only on each machine.

`ssh/allowed_signers` is the local trust list used by `git log --show-signature` and `git verify-commit`. It maps your email to your public key. GitHub's "Verified" badge uses its own registry (the signing key you registered there) and does not read this file.

### Devcontainer signing

The private key never enters the container. Instead, a dedicated `ssh-agent` runs on the WSL host and its socket is bind-mounted into the container. Git in the container signs via the forwarded socket — the private key bytes never leave the host.

The socket path is hardcoded rather than using `${localEnv:SSH_AUTH_SOCK}` because VS Code leaves that variable empty when it cold-launches a devcontainer without a prior WSL terminal session. `loginctl enable-linger` (see below) ensures the agent is running from WSL boot so the socket is always there when VS Code arrives.

Add these two keys to your **personal, gitignored** `devcontainer.json` override for each project (not the shared base — the mount path is machine-specific and will break teammates who don't have this setup):

```jsonc
"mounts": [
  "source=/run/user/1000/ssh-agent.socket,target=/run/ssh-agent.sock,type=bind"
],
"remoteEnv": {
  "SSH_AUTH_SOCK": "/run/ssh-agent.sock"
}
```

Then rebuild the container. The `.bashrc` guard leaves `SSH_AUTH_SOCK` alone when the container's `remoteEnv` value already points at a live socket, so the host path never overrides the container path.

### One-time host setup (WSL2)

Do these steps once on the WSL host. Containers pick up signing automatically after that.

**1. Generate the signing key** (skip if `~/.ssh/git_signing` already exists):

```bash
ssh-keygen -t ed25519 -f ~/.ssh/git_signing -C "git signing" -N ""
```

**2. Clone and run `install.sh` on the host** — this is separate from the container install. It symlinks the systemd unit and enables the ssh-agent service:

```bash
git clone git@github.com:a18rhodes/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

**3. Enable linger** so the ssh-agent service starts at WSL boot without requiring an interactive login:

```bash
loginctl enable-linger $USER
```

**4. Load the signing key into the agent:**

```bash
ssh-add ~/.ssh/git_signing
```

Subsequent shells do this automatically via `.bashrc`. After a WSL restart the service comes back up on its own, but the key needs to be re-added the first time you open a terminal (`.bashrc` handles it).

**5. Register the public key on GitHub** as a **Signing Key** (Settings → SSH and GPG keys → New SSH key, Key type: Signing Key). This is separate from any authentication key already there.

## Installation

In every context below, the underlying operation is the same:

```bash
git clone git@github.com:a18rhodes/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

Set `DOTFILES_PROJECT_ROOT` to a project path before running `install.sh` to also inject `agent-instructions.md` into that project. Without it, `install.sh` still links the home-directory files and Claude settings, and just skips project injection.

### Devcontainer-based project

Use the Dev Container spec's built-in `dotfiles` block so the clone-and-install step happens automatically on every container create/rebuild — no manual step, ever:

```jsonc
// .devcontainer/devcontainer.json
{
  "containerEnv": {
    "DOTFILES_PROJECT_ROOT": "${containerWorkspaceFolder}"
  },
  "dotfiles": {
    "repository": "https://github.com/a18rhodes/dotfiles",
    "targetPath": "~/dotfiles",
    "installCommand": "~/dotfiles/install.sh"
  }
}
```

This is per-project and travels with the repo, which is right for a repo you own. If you'd rather have it apply to *every* devcontainer you open, regardless of whether that project's `devcontainer.json` declares a `dotfiles` block, set the same three values once in your own VS Code user `settings.json` instead (Dev Containers extension picks them up for any container):

```json
{
  "dotfiles.repository": "a18rhodes/dotfiles",
  "dotfiles.targetPath": "~/dotfiles",
  "dotfiles.installCommand": "install.sh"
}
```

Either way, your shell config and default Claude Code settings are back the moment the container finishes building.

### Standard project in VS Code (no devcontainer)

Clone once per machine, then run `install.sh` from VS Code's integrated terminal, pointing it at the project you have open:

```bash
git clone git@github.com:a18rhodes/dotfiles.git ~/dotfiles
DOTFILES_PROJECT_ROOT="$(pwd)" ~/dotfiles/install.sh
```

Re-run that second line in any other project directory you want the agent instructions injected into. The shell and Claude Code settings only need to be linked once per machine.

### Any Unix environment (no VS Code)

Same as above, minus the project-injection step if there's no project to inject into:

```bash
git clone git@github.com:a18rhodes/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

Add `git config --global include.path "~/dotfiles/.gitconfig"` manually if you're on a machine where `install.sh` didn't already do it for you (it does this automatically as its last step).
