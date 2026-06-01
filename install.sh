#!/bin/bash

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
INSTRUCTIONS="$DOTFILES/agent-instructions.md"

ln -sf "$DOTFILES/.bashrc" ~/.bashrc
ln -sf "$DOTFILES/.vimrc" ~/.vimrc
ln -sf "$DOTFILES/.tmux.conf" ~/.tmux.conf

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
description: Pragmatic Craftsman engineering standards and Gilfoyle persona
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
