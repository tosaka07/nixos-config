#!/usr/bin/env bash

git_root=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$git_root" ]; then
  tmux display-message "Not in a git repository"
  exit 1
fi

# Get existing worktrees
worktrees=$(git worktree list --porcelain | grep "^worktree" | cut -d" " -f2-)
branches=$(git branch -a --format="%(refname:short)" | grep -v HEAD)

# Create fzf input with existing worktrees marked
fzf_input=""
for branch in $branches; do
  is_worktree=0
  for wt in $worktrees; do
    if [[ "$wt" == *"/$branch" ]] || [[ "$wt" == *"/$branch"$ ]]; then
      is_worktree=1
      break
    fi
  done
  if [ $is_worktree -eq 1 ]; then
    fzf_input+="✓ $branch\n"
  else
    fzf_input+="  $branch\n"
  fi
done

# Use fzf to select or input new branch
selected=$(echo -e "$fzf_input" | fzf-tmux -p 80% \
  --layout=reverse \
  --header "Select existing worktree (✓) or branch, or type new branch name" \
  --preview "git log --color=always --oneline -10 {2}" \
  --preview-window down:50%:sharp \
  --print-query)

# Handle fzf output
readarray -t selection <<<"$selected"
if [ ${#selection[@]} -eq 0 ]; then
  exit 0
elif [ ${#selection[@]} -eq 1 ]; then
  # User typed a new branch name
  branch_name="${selection[0]}"
  is_new_branch=1
else
  # User selected an existing item
  branch_name=$(echo "${selection[1]}" | sed "s/^[✓ ]* //")
  is_new_branch=0
  # Check if it is an existing worktree
  for wt in $worktrees; do
    if [[ "$wt" == *"/$branch_name" ]] || [[ "$wt" == *"/$branch_name"$ ]]; then
      # Existing worktree
      current_dir=$(pwd)
      if [ "$current_dir" = "$wt" ]; then
        # Already in the right window/directory
        tmux display-message "Already in worktree: $branch_name"
        exit 0
      else
        # Check if there is a tmux window for this worktree
        if tmux list-windows -F "#W" | grep -q "^$branch_name$"; then
          # Window exists, switch to it
          tmux select-window -t "$branch_name"
        else
          # No window exists, create new window
          tmux new-window -n "$branch_name" -c "$wt"
          tmux send-keys -t "$branch_name" vim C-m
          tmux split-window -h -l 30% -t "$branch_name" -c "$wt" claude
          tmux select-pane -t "$branch_name.0"
        fi
        exit 0
      fi
    fi
  done
fi

# Clean up branch name (remove origin/ prefix if present)
clean_branch="${branch_name#origin/}"

# Create worktree path
worktree_path="$git_root/.git/worktrees/$clean_branch"

# Create the worktree
if [ $is_new_branch -eq 1 ]; then
  git worktree add "$worktree_path" -b "$clean_branch" 2>/dev/null
else
  git worktree add "$worktree_path" "$branch_name" 2>/dev/null
fi

if [ $? -ne 0 ]; then
  tmux display-message "Failed to create worktree"
  exit 1
fi

# Create new tmux window and setup panes
tmux new-window -n "$clean_branch" -c "$worktree_path"
tmux send-keys -t "$clean_branch" vim C-m
tmux split-window -h -l 30% -t "$clean_branch" -c "$worktree_path" claude
tmux select-pane -t "$clean_branch.0"
