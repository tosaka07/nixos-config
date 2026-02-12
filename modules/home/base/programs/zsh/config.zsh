
# ----------------------------------------------
# Util: functions
# ----------------------------------------------
function source_defer() {
  zsh-defer -c "test -e $1 && source $1 || true"
}


# ----------------------------------------------
# Library: homebrew
# ----------------------------------------------
local brew_path="$HOMEBREW_PREFIX/bin/brew"
local brew_script_path="${script_dir}/_brew"
if [ ! -f "$brew_script_path" ]; then
  eval "source <($brew_path shellenv)"
fi
(eval "$brew_path shellenv > $brew_script_path" &) > /dev/null 2>&1

# ----------------------------------------------
# Determinate Nixd completion
# ----------------------------------------------
# if command -v determinate-nixd &> /dev/null; then
#     eval "$(determinate-nixd completion zsh)"
# fi

# ----------------------------------------------
# Path
# (N-/): ディレクトリが存在するときだけ path に追加する (symlink 含む)
# ----------------------------------------------
export PNPM_HOME="$HOME/Library/pnpm"

path=(
  # Dart
  $HOME/.pub-cache/bin(N-/)
  # Rust
  $HOME/.cargo/bin(N-/)
  # rye
  $HOME/.rye/shims(N-/)
  # Android
  $HOME/Library/Android/sdk/platform-tools(N-/)
  # istioctl
  $HOME/.istioctl/bin(N-/)
  # pnpm
  $PNPM_HOME(N-/)
  # base
  $path
)

# Remove duplicates PATH
typeset -gU PATH

# ----------------------------------------------
# Variables
# ----------------------------------------------
export FZF_TMUX=1
export FZF_TMUX_OPTS="-p"

# ----------------------------------------------
# Library: mise
# ----------------------------------------------
if command -v mise &> /dev/null; then
    eval "$(mise activate zsh)"
    export FLUTTER_ROOT="$(mise where flutter)"
fi

# ----------------------------------------------
# Library: atuin
# ----------------------------------------------
if command -v atuin &> /dev/null; then
    eval "$(atuin init zsh)"
fi

# ----------------------------------------------
# Library: sheldon
# ----------------------------------------------
if command -v sheldon &> /dev/null; then
    eval "$(sheldon source)"
fi

# ----------------------------------------------
# Library: fzf
# ----------------------------------------------
export FZF_DEFAULT_OPTS="\
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

# ----------------------------------------------
# Library: neovim
# ----------------------------------------------
if command -v nvim &> /dev/null; then
    export EDITOR=nvim
    export VISUAL=nvim
    alias vi="nvim"
    alias vim="nvim"
fi

# ----------------------------------------------
# Library: eza
# ----------------------------------------------
if command -v eza &> /dev/null; then
    alias ls="eza"
    alias ll="eza -lF --time-style=long-iso"
    alias la="eza -laF --time-style=long-iso"
    alias lt="eza -T"
    alias lta="eza -T -a"
    alias tree="eza -TF"
fi

# ----------------------------------------------
# Library: zoxide
# ----------------------------------------------
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
    alias cd="z"
fi

# ----------------------------------------------
# Library: gitui
# ----------------------------------------------
if command -v gitui &> /dev/null; then
    alias gitui="gitui -t mocha.ron"
fi

# ----------------------------------------------
# Library: gomi
# ----------------------------------------------
if command -v gomi &> /dev/null; then
    alias rm='gomi'
fi

# ----------------------------------------------
# Library: yq
# ----------------------------------------------
if command -v yq &> /dev/null; then
    alias yqjson="yq -o json"
    alias yqyaml="yq -o yaml -P"
fi

# ----------------------------------------------
# Library: task
# ----------------------------------------------
if command -v task &> /dev/null; then
    alias t="task"
fi

# ----------------------------------------------
# Library: Orbstack
# ----------------------------------------------
if command -v orb &> /dev/null; then
    source_defer ~/.orbstack/shell/init.zsh
fi

# ----------------------------------------------
# Library: 1password
# ----------------------------------------------
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# ----------------------------------------------
# Zsh Plugin: zsh-dirnav
# ----------------------------------------------
SHIFT_LEFT="^[[1;2D"
SHIFT_RIGHT="^[[1;2C"
bindkey $SHIFT_LEFT cd-back
bindkey $SHIFT_RIGHT cd-forward

# ----------------------------------------------
# Functions
# ----------------------------------------------

# Change directory to selected local repo managed by ghq
function ghq_cd_fzf() {
    local src
    src=$(ghq list | fzf-tmux -p 80% -q "$BUFFER" --layout=reverse --preview "glow --style dark --width 80 $(ghq root)/{}/README.md")
    if [[ -n "$src" ]]; then
        cd "$(ghq root)/$src"
        zle reset-prompt
    fi
}
zle -N ghq_cd_fzf
bindkey '^g' ghq_cd_fzf

# Change directory to selected directory managed by zoxide
function zoxide_fzf() {
    local src
    src=$(zoxide query --list | fzf-tmux -p -q "$BUFFER" --layout=reverse --cycle --preview='ls {} --color always' --preview-window=down,30%,sharp)
    if [[ -n "$src" ]]; then
        cd "$src"
        zle reset-prompt
    fi
}
zle -N zoxide_fzf
alias cdd=zoxide_fzf

# Add dependencies to current directory with mise
function mise_fzf() {
    local src_line _language _version _source _required
    src_line=$(mise list --installed | fzf-tmux -p --header "Select the library to install." --layout=reverse --cycle)
    read _language _version _source _required <<< "$src_line"
    print -z "mise use $_language@$_version"
}
alias misef=mise_fzf

# Check out git branch
function git_branch_fzf() {
    local branch_name new_local_branch_name
    branch_name=$(git branch -a --format='%(refname:short)' | grep -v "$(git branch --show-current)" | fzf-tmux -p 80% --layout reverse --cycle --header "Select the branch to checkout as new branch." --preview 'git log --color=always {}' --preview-window down:50%:sharp)

    if [[ "$branch_name" == origin/* ]]; then
        new_local_branch_name="${branch_name#origin/}"
        if [[ -n "$new_local_branch_name" ]]; then
            git checkout -b "$new_local_branch_name" "$branch_name"
        fi
    else
        if [[ -n "$branch_name" ]]; then
            git checkout "$branch_name"
        fi
    fi
    zle reset-prompt 2>/dev/null || true
}
alias gitb=git_branch_fzf

# Git worktree management
function wt() {
    if [[ -n "$TMUX" ]]; then
        echo "Use tmux keybind: C-Space C-w"
        tmux send-keys C-Space C-w
    else
        echo "This command requires tmux. Please run in a tmux session."
        echo "After starting tmux, use: C-Space C-w"
    fi
}

# gwm で worktree を選択し、開発環境を構築する
# レイアウト: 左ペイン(claude) | 右上ペイン(vim) | 右下ペイン(terminal)
function gwmt() {
    local dir win_name

    # gwm で worktree を選択
    dir=$(gwm -p)

    if [[ -z "$dir" || ! -d "$dir" ]]; then
        return 0
    fi

    win_name=$(basename "$dir")

    # 開発環境を構築
    tmux new-window -c "$dir" -n "$win_name"
    tmux split-window -h -c "$dir" -l 40%
    tmux split-window -v -c "$dir" -l 40%
    tmux select-pane -t 0
    tmux send-keys "claude" Enter
    tmux select-pane -t 1
    tmux send-keys "vim ." Enter
    tmux select-pane -t 2
}

# Create tmux pane on right with 30% width and launch claude
function cc() {
    if [[ -n "$TMUX" ]]; then
        tmux split-window -h -l 30% claude
    else
        echo "Not in a tmux session"
    fi
}


# Activate gcloud config and sync ADC quota-project
function gcfg() {
    local config project_id
    config=$(gcloud config configurations list --format="value(name)" | fzf --prompt="Choose config > ")
    if [[ -n "$config" ]]; then
        gcloud config configurations activate "$config"
        echo "Switched to gcloud config: $config"

        project_id=$(gcloud config get-value project 2>/dev/null)

        if [[ -n "$project_id" && "$project_id" != "(unset)" ]]; then
            gcloud auth application-default set-quota-project "$project_id"
            echo "Updated ADC quota-project -> $project_id"
        else
            echo "Warning: Active config has no project set. Skipped ADC quota-project update."
        fi
    else
        echo "No config selected"
    fi
}
