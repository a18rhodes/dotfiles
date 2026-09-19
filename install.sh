#!/bin/bash

CLAUDE_SETTINGS=~/.claude/settings.json
CLAUDE_TEMPLATE="$DOTFILES/claude-settings.json"
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
INSTRUCTIONS="$DOTFILES/agent-instructions.md"

ln -sf "$DOTFILES/.bashrc" ~/.bashrc
ln -sf "$DOTFILES/.vimrc" ~/.vimrc
ln -sf "$DOTFILES/.tmux.conf" ~/.tmux.conf

mkdir -p ~/.claude
if [ ! -f "$CLAUDE_SETTINGS" ]; then
    cp "$CLAUDE_TEMPLATE" "$CLAUDE_SETTINGS"
    echo "Claude Code settings installed."
elif command -v jq >/dev/null 2>&1; then
    # One-way, top-level-only merge: dotfiles-managed keys (model, notifications, ...) always
    # win; anything else already in the live file (e.g. permissions Claude wrote locally) is
    # left alone and never flows back into the dotfiles repo. Only safe while the template stays
    # flat: a future nested key here would replace the whole nested object, not merge inside it.
    TMP="$(mktemp)"
    if jq -s '.[0] + .[1]' "$CLAUDE_SETTINGS" "$CLAUDE_TEMPLATE" > "$TMP"; then
        mv "$TMP" "$CLAUDE_SETTINGS"
        echo "Claude Code settings merged (jq)."
    else
        rm -f "$TMP"
        echo "jq merge failed (invalid JSON in $CLAUDE_SETTINGS?); left existing settings untouched."
    fi
elif command -v python3 >/dev/null 2>&1; then
    if python3 - "$CLAUDE_SETTINGS" "$CLAUDE_TEMPLATE" <<'PY'
import json, sys
existing_path, template_path = sys.argv[1], sys.argv[2]
with open(existing_path) as f:
    existing = json.load(f)
with open(template_path) as f:
    template = json.load(f)
existing.update(template)
with open(existing_path, "w") as f:
    json.dump(existing, f, indent=2)
    f.write("\n")
PY
    then
        echo "Claude Code settings merged (python3)."
    else
        echo "python3 merge failed (invalid JSON in $CLAUDE_SETTINGS?); left existing settings untouched."
    fi
else
    cp "$CLAUDE_TEMPLATE" "$CLAUDE_SETTINGS"
    echo "Neither jq nor python3 found; overwrote $CLAUDE_SETTINGS with dotfiles defaults (any local-only keys were lost)."
fi

PROJECT_ROOT="${DOTFILES_PROJECT_ROOT:-}"
if [ -z "$PROJECT_ROOT" ] || [ ! -d "$PROJECT_ROOT" ]; then
    echo "DOTFILES_PROJECT_ROOT not set; skipping project injection."
elif [ ! -f "$INSTRUCTIONS" ]; then
    echo "Missing $INSTRUCTIONS; skipping project injection."
else
    echo "Found project root at: $PROJECT_ROOT"

    # Claude Code: plain markdown at ./.claude/CLAUDE.md (or ./CLAUDE.md)
    mkdir -p "$PROJECT_ROOT/.claude"
    ln -sf "$INSTRUCTIONS" "$PROJECT_ROOT/.claude/CLAUDE.md"
    echo "Claude instructions injected."

    # GitHub Copilot: plain markdown at .github/copilot-instructions.md (auto-applies workspace-wide)
    mkdir -p "$PROJECT_ROOT/.github"
    ln -sf "$INSTRUCTIONS" "$PROJECT_ROOT/.github/copilot-instructions.md"
    echo "Copilot instructions injected."

    # Cursor: .mdc with YAML frontmatter in .cursor/rules/ (plain .md is ignored)
    mkdir -p "$PROJECT_ROOT/.cursor/rules"
    {
        cat <<'EOF'
---
description: Pragmatic Craftsman engineering standards
alwaysApply: true
---
EOF
        cat "$INSTRUCTIONS"
    } > "$PROJECT_ROOT/.cursor/rules/craftsman.mdc"
    echo "Cursor rules injected."

    GITIGNORE="$PROJECT_ROOT/.gitignore"
    if [ -f "$GITIGNORE" ]; then
        append_gitignore() {
            local pattern="$1"
            local comment="$2"
            if ! grep -qF "$pattern" "$GITIGNORE"; then
                echo "" >> "$GITIGNORE"
                echo "$comment" >> "$GITIGNORE"
                echo "$pattern" >> "$GITIGNORE"
            fi
        }
        append_gitignore ".claude/*" "# Private AI instructions (Injected by Dotfiles)"
        append_gitignore ".github/copilot-instructions.md" "# Private AI instructions (Injected by Dotfiles)"
        append_gitignore ".cursor/*" "# Private AI instructions (Injected by Dotfiles)"
    fi
fi

git config --global include.path "~/dotfiles/.gitconfig"

source ~/.bashrc
