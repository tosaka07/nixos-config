# Delete start message
set fish_greeting

# ----------------------------------------------
# Library: homebrew 
# ----------------------------------------------
eval (/opt/homebrew/bin/brew shellenv)

# ----------------------------------------------
# Determinate Nixd completion
# ----------------------------------------------
# if command -q determinate-nixd
#     eval "$(determinate-nixd completion fish)"
# end

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
set -gx ENABLE_TOOL_SEARCH true

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

if type -q fzf
    fzf --fish | source
end

# ----------------------------------------------
# Library: neovim
# ----------------------------------------------
if type -q nvim
    set -gx EDITOR nvim
    set -gx VISUAL nvim
    abbr --add vi nvim
    abbr --add vim nvim
end

# ----------------------------------------------
# Library: eza
# ----------------------------------------------
if type -q eza
    abbr --add ls eza
    abbr --add ll "eza -lF --time-style=long-iso"
    abbr --add la "eza -laF --time-style=long-iso"
    abbr --add lt "eza -T"
    abbr --add lta "eza -T -a"
    abbr --add tree "eza -TF"
end

# ----------------------------------------------
# Library: zoxide
# ----------------------------------------------
if type -q zoxide
    zoxide init fish | source
    abbr --add cd z
end

# ----------------------------------------------
# Library: gitui
# ----------------------------------------------
if type -q gitui
    abbr --add gitui "gitui -t mocha.ron"
end

# ----------------------------------------------
# Library: gomi
# ----------------------------------------------
if type -q gomi
    abbr --add rm gomi
end

# ----------------------------------------------
# Library: yq
# ----------------------------------------------
if type -q yq
    abbr --add yqjson "yq -o json"
    abbr --add yqyaml "yq -o yaml -P"
end

# ----------------------------------------------
# Library: zoxide
# ----------------------------------------------
if type -q task
    abbr --add t task
end

# Claude Code
if type -q claude
    abbr --add cc claude
end

# difit
abbr --add difit "npx difit"

# ----------------------------------------------
# Library: Orbstack
# ----------------------------------------------
if type -q orb
    source ~/.orbstack/shell/init2.fish 2>/dev/null || :
end

# ----------------------------------------------
# Library: pnpm
# ----------------------------------------------
set -gx PNPM_HOME ~/Library/pnpm
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end

# ----------------------------------------------
# Library: 1password
# ----------------------------------------------
set -gx SSH_AUTH_SOCK ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

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
bind ctrl-g ghq_cd_fzf

# Replace to atuin
# function history_fzf -d "Fuzzy search history"
#     set -l input (commandline)
#     set cmd (history | fzf-tmux -p 80% -q "$input" --layout reverse)
#     if test -n "$cmd"
#         commandline -r -- "$cmd"
#     end
# end
# bind \cr history_fzf

function zoxide_fzf -d "Change directory to selected directory managed by zoxide"
    set -l input (commandline)
    set src (zoxide query --list | fzf-tmux -p -q "$input" --layout=reverse --cycle --preview='ls {} --color always --icons' --preview-window=down,30%,sharp)
    if test -n "$src"
        cd $src
        commandline -f repaint
    end
end
abbr --add cdd zoxide_fzf

function mise_fzf -d "Add dependencies to current directory with mise"
    set src_line (mise list --installed | fzf-tmux -p -q "$input" --header "Select the library to install." --layout=reverse --cycle)
    echo $src_line | read -l _language _version _source _required
    commandline -r -- "mise use $_language@$_version"
end
abbr --add misef mise_fzf

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
abbr --add gitb git_branch_fzf

function wt -d "Git worktree management (use tmux C-Space C-w)"
    if test -n "$TMUX"
        echo "Use tmux keybind: C-Space C-w"
        tmux send-keys C-Space C-w
    else
        echo "This command requires tmux. Please run in a tmux session."
        echo "After starting tmux, use: C-Space C-w"
    end
end

function cc -d "Create tmux pane on right with 30% width and launch claude"
    if test -n "$TMUX"
        tmux split-window -h -l 30% claude
    else
        echo "Not in a tmux session"
    end
end

function tmux-agent-panel -d "Create an agentic coding tmux layout for a target directory"
    set -l dir

    if test (count $argv) -gt 0
        set dir (path normalize (string replace -r '^~' $HOME -- $argv[1]))
    else
        set dir (pwd)
    end

    if not test -d "$dir"
        echo "Directory not found: $dir" >&2
        return 1
    end

    set -l name (basename "$dir")
    set -l agent_cmd "claude"
    set -l editor_cmd "nvim ."
    set -l shell_cmd $SHELL

    if test -z "$shell_cmd"
        set shell_cmd "fish"
    end

    if test -n "$TMUX"
        set -l window_id (tmux new-window -P -F "#{window_id}" -c "$dir" -n "$name")
        set -l left_target "$window_id".0
        set -l editor_target "$window_id".1
        set -l terminal_target "$window_id".2
        tmux split-window -h -t "$window_id" -c "$dir" -l 40%
        tmux split-window -v -t "$editor_target" -c "$dir" -l 35%
        tmux select-pane -t "$left_target"
        tmux send-keys -t "$left_target" "$agent_cmd" Enter
        tmux send-keys -t "$editor_target" "$editor_cmd" Enter
        tmux send-keys -t "$terminal_target" "$shell_cmd" Enter
        tmux select-pane -t "$editor_target"
        return 0
    end

    set -l session_name "$name"
    set -l suffix 1
    while tmux has-session -t "$session_name" 2>/dev/null
        set session_name "$name-$suffix"
        set suffix (math $suffix + 1)
    end

    tmux new-session -d -s "$session_name" -c "$dir" -n "$name"
    set -l window_target "$session_name":"$name"
    set -l left_target "$window_target".0
    set -l editor_target "$window_target".1
    set -l terminal_target "$window_target".2
    tmux split-window -h -t "$window_target" -c "$dir" -l 40%
    tmux split-window -v -t "$editor_target" -c "$dir" -l 35%
    tmux send-keys -t "$left_target" "$agent_cmd" Enter
    tmux send-keys -t "$editor_target" "$editor_cmd" Enter
    tmux send-keys -t "$terminal_target" "$shell_cmd" Enter
    tmux select-pane -t "$editor_target"
    tmux attach-session -t "$session_name"
end

function wta -d "Switch to a worktree with worktrunk and open tmux-agent-panel"
    if test (count $argv) -eq 0
        set -l branch (wt switch --no-cd)

        if test $status -ne 0
            return $status
        end

        if test -z "$branch"
            return 0
        end

        wt switch --execute "fish -ic 'tmux-agent-panel {{ worktree_path }}'" "$branch"
        return $status
    end

    wt switch --execute "fish -ic 'tmux-agent-panel {{ worktree_path }}'" $argv
end

function __nifuramu_default_branch
    set -l remote_head (git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
    if test -n "$remote_head"
        string replace "origin/" "" -- "$remote_head"
        return 0
    end

    for candidate in main master
        if git show-ref --verify --quiet "refs/remotes/origin/$candidate"
            echo "$candidate"
            return 0
        end
    end

    for candidate in main master
        if git show-ref --verify --quiet "refs/heads/$candidate"
            echo "$candidate"
            return 0
        end
    end
end

function __nifuramu_worktree_path_for_branch --argument branch
    git worktree list --porcelain | awk -v branch_ref="refs/heads/$branch" '
        /^worktree / { wt = substr($0, 10) }
        /^branch / && $2 == branch_ref { print wt; exit }
    '
end

function nifuramu -d "Prune merged branches and their worktrees"
    if not git rev-parse --show-toplevel >/dev/null 2>/dev/null
        echo "Not in a git repository" >&2
        return 1
    end

    set -l current_worktree (path normalize (git rev-parse --show-toplevel))
    git fetch --prune
    if test $status -ne 0
        echo "git fetch --prune failed" >&2
        return 1
    end

    set -l default_branch (__nifuramu_default_branch)
    if test -z "$default_branch"
        echo "Could not determine default branch" >&2
        return 1
    end

    set -l base_ref "refs/remotes/origin/$default_branch"
    if not git show-ref --verify --quiet "$base_ref"
        set base_ref "refs/heads/$default_branch"
    end

    set -l merged_branches (git for-each-ref --format='%(refname:short)' --merged="$base_ref" refs/heads)
    set -l protected_branches $default_branch main master
    set -l targets

    for branch in $merged_branches
        if contains -- "$branch" $protected_branches
            continue
        end
        set targets $targets $branch
    end

    if test (count $targets) -eq 0
        echo "No merged branches or worktrees to prune"
        return 0
    end

    set -l exit_code 0

    for branch in $targets
        set -l worktree_path (__nifuramu_worktree_path_for_branch "$branch")
        if test -n "$worktree_path"
            set worktree_path (path normalize "$worktree_path")

            if test "$worktree_path" = "$current_worktree"
                echo "Skip current worktree: $worktree_path"
                continue
            end

            git worktree remove "$worktree_path"
            if test $status -ne 0
                set exit_code 1
                continue
            end

            echo "Removed worktree: $worktree_path"
        end

        git branch -D "$branch"
        if test $status -ne 0
            set exit_code 1
            continue
        end

        echo "Deleted branch: $branch"
    end

    return $exit_code
end

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
bind shift-left prevd_without_newline

function nextd_without_newline
    nextd >/dev/null
    commandline -f repaint
end
bind shift-right nextd_without_newline

function cd_parent_without_newline
    cd ..
    commandline -f repaint
end
bind shift-up cd_parent_without_newline

function dirh_fzf_without_newline
    set -l all_dirs $dirprev $dirnext
    if not set -q all_dirs[1]
        echo "No directory history. Use cd a few times first."
        commandline -f repaint
        return 0
    end

    set -l uniq_dirs
    for dir in $all_dirs[-1..1]
        if not contains -- $dir $uniq_dirs
            set -a uniq_dirs $dir
        end
    end

    set -l preview_cmd 'if command -q eza; eza -laF --time-style=long-iso --color always {}; else ls -la {}; end'
    set -l selected_dir (printf "%s\n" $uniq_dirs | fzf --layout=reverse --height 40% --preview $preview_cmd --query "$PWD")

    if test -n "$selected_dir"
        cd -- $selected_dir
    end

    commandline -f repaint
end
bind shift-down dirh_fzf_without_newline

bind alt-left prevd_without_newline
bind alt-right nextd_without_newline
bind alt-up cd_parent_without_newline
bind alt-down dirh_fzf_without_newline

# Raw sequences for terminals/tmux that don't resolve symbolic modified arrows.
bind \e\[1\;2D prevd_without_newline
bind \e\[1\;2C nextd_without_newline
bind \e\[1\;2A cd_parent_without_newline
bind \e\[1\;2B dirh_fzf_without_newline
bind \e\[1\;3D prevd_without_newline
bind \e\[1\;3C nextd_without_newline
bind \e\[1\;3A cd_parent_without_newline
bind \e\[1\;3B dirh_fzf_without_newline

function clia
    read -l line
    commandline -a $line
    # commandline -a 
end

# 実行可能なコマンドをfzfで選択して実行する
function fuzzy_complete
    complete -C | sort -u | fzf --height 40% --multi --reverse -q (commandline -t) | cut --output-delimiter ' ' -f1 | sed s/-//g | clia
    commandline -f end-of-line
end
bind --mode insert alt-t fuzzy_complete

# 1Password環境変数読み込み関数
function opr -d "Run command with 1Password environment variables"
    # Check if user is signed in to 1Password
    op whoami >/dev/null 2>&1
    if test $status -ne 0
        eval (op signin)
    end

    # Use local .env if exists, otherwise use global env file
    if test -f "$PWD/.env"
        op run --env-file=$PWD/.env -- $argv
    else
        # Using home directory as default global env location
        set -l global_env "$HOME/nixos-config/.env.op"
        if test -f "$global_env"
            op run --env-file=$global_env -- $argv
        else
            echo "Warning: No global .env.1password found at $global_env"
            echo "Running without env file..."
            op run -- $argv
        end
    end
end

function gcfg -d "Activate gcloud config and sync ADC quota-project"
    set config (gcloud config configurations list --format="value(name)" | fzf --prompt="Choose config > ")
    if test -n "$config"
        # Activate the selected config
        gcloud config configurations activate $config
        echo "Switched to gcloud config: $config"

        # Fetch project of the activated config
        set project_id (gcloud config get-value project 2>/dev/null)

        # If project is set, sync ADC quota-project to avoid quota mismatch warning
        if test -n "$project_id"; and not string match -q "(unset)" "$project_id"
            gcloud auth application-default set-quota-project "$project_id"
            echo "Updated ADC quota-project -> $project_id"
        else
            echo "Warning: Active config has no project set. Skipped ADC quota-project update."
        end
    else
        echo "No config selected"
    end
end
