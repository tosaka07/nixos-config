# Delete start message
set fish_greeting

# ----------------------------------------------
# Library: homebrew 
# ----------------------------------------------
eval (/opt/homebrew/bin/brew shellenv)

# ----------------------------------------------
# Determinate Nixd completion
# ----------------------------------------------
if command -q determinate-nixd
    eval "$(determinate-nixd completion fish)"
end

# ----------------------------------------------
# Path
# ----------------------------------------------
fish_add_path $HOME/.pub-cache/bin
fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/.rye/bin
fish_add_path $HOME/Library/Android/sdk/platform-tools
fish_add_path $HOME/.istioctl/bin

# ----------------------------------------------
# Aliases
# ----------------------------------------------

# ----------------------------------------------
# Variables
# ----------------------------------------------
set -g FZF_TMUX 1
set -g FZF_TMUX_OPTS -p

if type -q mise
    mise activate fish | source
    set -gx FLUTTER_ROOT "$(mise where flutter)"
end

# ----------------------------------------------
# Library: atuin
# ----------------------------------------------
if type -q atuin
    atuin init fish | source
end

# ----------------------------------------------
# Library: fzf
# ----------------------------------------------
set -Ux FZF_DEFAULT_OPTS "\
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

# ----------------------------------------------
# Library: neovim
# ----------------------------------------------
if type -q nvim
    set -gx EDITOR nvim
    set -gx VISUAL nvim
    alias vi="nvim"
    alias vim="nvim"
end

# ----------------------------------------------
# Library: eza
# ----------------------------------------------
if type -q eza
    alias ls="eza"
    alias ll="eza -lF --time-style=long-iso"
    alias la="eza -laF --time-style=long-iso"
    alias lt="eza -T"
    alias lta="eza -T -a"
    alias tree="eza -TF"
end

# ----------------------------------------------
# Library: zoxide
# ----------------------------------------------
if type -q zoxide
    zoxide init fish | source
    alias cd="z"
end

# ----------------------------------------------
# Library: zoxide
# ----------------------------------------------
if type -q gitui
    alias gitui="gitui -t mocha.ron"
end

# ----------------------------------------------
# Library: mise
# ----------------------------------------------
if type -q trash-put
    alias rm='trash-put'
end

# ----------------------------------------------
# Library: yq
# ----------------------------------------------
if type -q yq
    alias yqjson="yq -o json"
    alias yqyaml="yq -o yaml -P"
end

# ----------------------------------------------
# Library: zoxide
# ----------------------------------------------
if type -q task
    alias t="task"
end

# ----------------------------------------------
# Functions
# ----------------------------------------------
function ghq_cd_fzf -d "Change dirctory to selected local repo managed by ghq."
    set -l input (commandline)
    set src (ghq list | fzf-tmux -p 80% -q "$input" --layout=reverse --preview "glow --style dark --width 80 "(ghq root)"/{}/README.md")
    if test -n "$src"
        cd (ghq root)/"$src"
        commandline -f repaint
    end

end
bind \cg ghq_cd_fzf

function history_fzf -d "Fuzzy search history"
    set -l input (commandline)
    set cmd (history | fzf-tmux -p 80% -q "$input" --layout reverse)
    if test -n "$cmd"
        commandline -r -- "$cmd"
    end
end
# bind \cr history_fzf

function zoxide_fzf -d "Change directory to selected directory managed by zoxide"
    set -l input (commandline)
    set src (zoxide query --list | fzf-tmux -p -q "$input" --layout=reverse --cycle --preview='ls {} --color always --icons' --preview-window=down,30%,sharp)
    if test -n "$src"
        cd $src
        commandline -f repaint
    end
end
alias cdd=zoxide_fzf

function mise_fzf -d "Add dependencies to current directory with mise"
    set src_line (mise list --installed | fzf-tmux -p -q "$input" --header "Select the library to install." --layout=reverse --cycle)
    echo $src_line | read -l _language _version _source _required
    commandline -r -- "mise use $_language@$_version"
end
alias misef=mise_fzf

function git_branch_fzf -d "Check out new branch"
    set branch_name (git branch -a --format='%(refname:short)' | grep -v "$(git branch --show-current)" | fzf-tmux -p 80% --layout reverse --cycle --header "Select the branch to checkout as new branch." --preview 'git log --color=always {}' --preview-window down:50%:sharp)

    if string match -q "origin/*" $branch_name
        set new_local_branch_name (string replace "origin/" "" $branch_name)
        if test -n "$new_local_branch_name"
            git checkout -b $new_local_branch_name $branch_name
        end
    else
        if test -n "$branch_name"
            git checkout $branch_name
        end
    end
    commandline -f repaint
end
alias gitb git_branch_fzf

function aicommit -d "Generate commit message"
    set prompt """
    Generate a concise git commit message in present tense for the given code diff, following the specifications below:
    Exclude anything unnecessary such as translation. Your entire response will be passed directly into git commit.
    The entire response will be passed directly into the git commit.

    # Format
    <type>(<optional scope>): <description>

    # <type>
    - feat: 新機能
    - fix: バグ修正
    - refactor: リファクタリングのための変更（機能追加やバグ修正を含まない）
    - perf: パフォーマンスの改善のための変更
    - test: 不足テストの追加や既存テストの修正
    - style: フォーマットの変更（コードの動作に影響しないスペース、フォーマット、セミコロンなど）
    - build: ビルドシステムや外部依存に関する変更（例: npm, pub, gradle）
    - ci: CI用の設定やスクリプトに関する変更（例: Circle, Bitrise)
    - chore: 雑事（カテゴライズする必要ないようなもの）
    - docs: ドキュメントのみの変更
    - revert: コミット取り消し（git revert）

    # <description>
    Use Japanese.
    """
    git diff --staged | llm -s $prompt | git commit -e -F -
end

function aicommit_test -d "Generate commit message"
    set prompt """
    Generate a concise git commit message in present tense for the given code diff, following the specifications below:
    Exclude anything unnecessary such as translation. Your entire response will be passed directly into git commit.
    The entire response will be passed directly into the git commit.

    # Format
    <type>(<optional scope>): <description>

    # <type>
    - feat: 新機能
    - fix: バグ修正
    - refactor: リファクタリングのための変更（機能追加やバグ修正を含まない）
    - perf: パフォーマンスの改善のための変更
    - test: 不足テストの追加や既存テストの修正
    - style: フォーマットの変更（コードの動作に影響しないスペース、フォーマット、セミコロンなど）
    - build: ビルドシステムや外部依存に関する変更（例: npm, pub, gradle）
    - ci: CI用の設定やスクリプトに関する変更（例: Circle, Bitrise)
    - chore: 雑事（カテゴライズする必要ないようなもの）
    - docs: ドキュメントのみの変更
    - revert: コミット取り消し（git revert）

    # <description>
    Use Japanese.
    """
    git diff --staged | llm -s $prompt
end

function prevd_without_newline
    prevd >/dev/null
    commandline -f repaint
end
bind \e\[1\;2D prevd_without_newline

function nextd_without_newline
    nextd >/dev/null
    commandline -f repaint
end
bind \e\[1\;2C nextd_without_newline

function cd_parent_without_newline
    cd ..
    commandline -f repaint
end
bind \e\[1\;2A cd_parent_without_newline

function cd_child_without_newline
    # Get all directories
    set child_dirs (exa -d */)

    # Check the number of directories
    if count $child_dirs >1
        # If more than one directory, use fzf to select
        set selected_dir (printf "%s\n" $child_dirs | fzf --layout=reverse --preview 'exa -l --time-style=long-iso {}')
    else if count $child_dirs = 1
        # If only one directory, select it directly
        set selected_dir $child_dirs
    end

    # If a directory was selected, move to it
    if test -n "$selected_dir"
        cd $selected_dir
    end

    commandline -f repaint
end
bind \e\[1\;2B cd_child_without_newline

function clia
    read -l line
    commandline -a $line
    # commandline -a 
end

bind -M insert \et fuzzy_complete

# 実行可能なコマンドをfzfで選択して実行する
function fuzzy_complete
    complete -C | sort -u | fzf --height 40% --multi --reverse -q (commandline -t) | cut --output-delimiter ' ' -f1 | sed s/-//g | clia
    commandline -f end-of-line
end

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :

# pnpm
set -gx PNPM_HOME ~/Library/pnpm
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
