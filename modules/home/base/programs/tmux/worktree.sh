#!/usr/bin/env bash

set -euo pipefail

# Get git root directory
git_root=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$git_root" ]; then
  tmux display-message "Not in a git repository"
  exit 1
fi

worktrees_dir="$git_root/.git/worktrees"

# Get list of existing worktrees with their paths
get_worktrees() {
  git worktree list --porcelain | awk '
    /^worktree / { path = substr($0, 10) }
    /^branch / {
      branch = substr($0, 8)
      gsub(/refs\/heads\//, "", branch)
      print branch "\t" path
    }
  '
}

# Get all branches (local + remote)
get_branches() {
  git branch -a --format="%(refname:short)" | grep -v HEAD | sed 's|^origin/||' | sort -u
}

# Find tmux pane with specific directory
find_pane_with_dir() {
  local target_dir="$1"
  tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} #{pane_current_path}" 2>/dev/null | \
    awk -v target="$target_dir" '$2 == target { print $1; exit }'
}

# Build fzf input list
build_fzf_list() {
  local current_dir
  current_dir=$(pwd)

  declare -A worktree_paths
  while IFS=$'\t' read -r branch path; do
    worktree_paths["$branch"]="$path"
  done < <(get_worktrees)

  for branch in $(get_branches); do
    if [ -n "${worktree_paths[$branch]:-}" ]; then
      local path="${worktree_paths[$branch]}"
      if [ "$path" = "$current_dir" ]; then
        echo -e "● $branch\t$path\t(current)"
      else
        echo -e "✓ $branch\t$path"
      fi
    else
      echo -e "  $branch\t-\t(no worktree)"
    fi
  done
}

# Delete worktree with confirmation
delete_worktree() {
  local branch="$1"
  local path="$2"

  if [ "$path" = "-" ] || [ -z "$path" ]; then
    tmux display-message "No worktree exists for $branch"
    return 1
  fi

  # Confirm deletion
  local confirm
  confirm=$(echo -e "Yes, delete\nNo, cancel" | fzf \
    --header "Delete worktree '$branch' at $path?" \
    --layout=reverse \
    --height=40%) || true

  if [ "$confirm" = "Yes, delete" ]; then
    git worktree remove "$path" --force 2>/dev/null || {
      tmux display-message "Failed to remove worktree: $branch"
      return 1
    }
    tmux display-message "Deleted worktree: $branch"
  fi
}

# Select base branch for new worktree
select_base_branch() {
  local new_branch="$1"
  local default_branch

  # Try to find default branch
  default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||') || default_branch="main"

  local branches
  branches=$(get_branches | while read -r b; do
    if [ "$b" = "$default_branch" ]; then
      echo "$b (default)"
    else
      echo "$b"
    fi
  done)

  local selected
  selected=$(echo "$branches" | fzf \
    --header "Creating '$new_branch' - Select base branch" \
    --layout=reverse \
    --preview "git log --color=always --oneline -15 {1}" \
    --preview-window right:50%) || true

  if [ -z "$selected" ]; then
    return 1
  fi

  echo "$selected" | awk '{print $1}'
}

# Create new worktree
create_worktree() {
  local branch="$1"
  local base_branch="$2"
  local worktree_path="$worktrees_dir/$branch"

  # Create worktrees directory if needed
  mkdir -p "$worktrees_dir"

  # Check if branch exists remotely or locally
  if git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null; then
    # Local branch exists
    git worktree add "$worktree_path" "$branch" 2>/dev/null
  elif git show-ref --verify --quiet "refs/remotes/origin/$branch" 2>/dev/null; then
    # Remote branch exists
    git worktree add "$worktree_path" "$branch" 2>/dev/null
  else
    # New branch
    git worktree add "$worktree_path" -b "$branch" "$base_branch" 2>/dev/null
  fi

  if [ $? -ne 0 ]; then
    tmux display-message "Failed to create worktree: $branch"
    return 1
  fi

  echo "$worktree_path"
}

# Switch to directory (check for existing pane first)
switch_to_dir() {
  local target_dir="$1"

  # Find existing pane with this directory
  local existing_pane
  existing_pane=$(find_pane_with_dir "$target_dir")

  if [ -n "$existing_pane" ]; then
    # Ask user if they want to switch to existing pane
    local choice
    choice=$(echo -e "Switch to existing pane\nOpen in current pane" | fzf \
      --header "Found existing pane at $target_dir" \
      --layout=reverse \
      --height=40%) || true

    if [ "$choice" = "Switch to existing pane" ]; then
      tmux switch-client -t "$existing_pane"
      return 0
    fi
  fi

  # cd in current pane
  tmux send-keys "cd '$target_dir'" Enter
}

# Main function
main() {
  local fzf_result
  fzf_result=$(build_fzf_list | fzf \
    --header "Worktrees: Enter=select/create, Ctrl-D=delete" \
    --layout=reverse \
    --delimiter=$'\t' \
    --with-nth=1,2,3 \
    --preview "git log --color=always --oneline -15 {1}" \
    --preview-window right:50% \
    --expect=ctrl-d \
    --print-query \
    --tabstop=4) || true

  # Parse fzf output
  local query key selection
  query=$(echo "$fzf_result" | sed -n '1p')
  key=$(echo "$fzf_result" | sed -n '2p')
  selection=$(echo "$fzf_result" | sed -n '3p')

  # Handle empty result (user cancelled)
  if [ -z "$key" ] && [ -z "$selection" ] && [ -z "$query" ]; then
    exit 0
  fi

  # Parse selection
  local branch path status
  if [ -n "$selection" ]; then
    branch=$(echo "$selection" | awk -F'\t' '{print $1}' | sed 's/^[●✓ ]* //')
    path=$(echo "$selection" | awk -F'\t' '{print $2}')
    status=$(echo "$selection" | awk -F'\t' '{print $3}')
  else
    # User typed a new branch name
    branch=$(echo "$query" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
  fi

  # Handle delete
  if [ "$key" = "ctrl-d" ]; then
    if [ -n "$selection" ] && [ "$path" != "-" ]; then
      delete_worktree "$branch" "$path"
    else
      tmux display-message "No worktree to delete"
    fi
    exit 0
  fi

  # Handle selection or creation
  if [ -n "$path" ] && [ "$path" != "-" ]; then
    # Existing worktree - switch to it
    if [ "$status" = "(current)" ]; then
      tmux display-message "Already in worktree: $branch"
      exit 0
    fi
    switch_to_dir "$path"
  else
    # Need to create worktree
    if [ -z "$branch" ]; then
      tmux display-message "No branch specified"
      exit 0
    fi

    # Check if this is an existing branch (local or remote)
    local needs_base=false
    if ! git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null && \
       ! git show-ref --verify --quiet "refs/remotes/origin/$branch" 2>/dev/null; then
      needs_base=true
    fi

    local worktree_path
    if [ "$needs_base" = true ]; then
      # New branch - need to select base
      local base_branch
      base_branch=$(select_base_branch "$branch")
      if [ -z "$base_branch" ]; then
        exit 0
      fi
      worktree_path=$(create_worktree "$branch" "$base_branch")
    else
      # Existing branch - just create worktree
      worktree_path=$(create_worktree "$branch" "")
    fi

    if [ -n "$worktree_path" ] && [ -d "$worktree_path" ]; then
      tmux display-message "Created worktree: $branch"
      switch_to_dir "$worktree_path"
    fi
  fi
}

main "$@"
