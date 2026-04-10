---
name: worktree-tmux
description: worktrunk の branch/worktree を `wta` で選択・作成し、tmux-agent-panel で開く。Use when: 「wta で開いて」「worktree を tmux で開いて」「branch を作って agent panel で開いて」「pr:123 を worktree で開いて」
allowed-tools: Bash(fish:*), Bash(git:*), Bash(pwd:*)
---

# Worktree Tmux Skill

`wta` を使って worktrunk の worktree を tmux の agentic coding レイアウトで開く。

この環境では `wta` は fish function。Codex のデフォルト shell が zsh のため、通常は `fish -ic 'wta ...'` で呼ぶ。

## 使い分け

- 引数なしで picker を開く: `fish -ic 'wta'`
- 既存 branch / shortcut を開く: `fish -ic 'wta feature-x'`
- 新規 branch と worktree を作る: `fish -ic 'wta --create feature-x'`
- base を指定して作る: `fish -ic 'wta --create feature-x --base main'`
- worktrunk shortcut を使う: `fish -ic 'wta -'`, `fish -ic 'wta ^'`, `fish -ic 'wta pr:123'`

## 実行前の確認

- 現在位置が対象 Git repository 配下か確認する
- worktrunk と tmux が利用可能か確認する
- 既存 tmux session を壊さない。`wta` / `tmux-agent-panel` に任せる

確認例:

```bash
pwd
git rev-parse --show-toplevel
fish -ic 'type -q wta; and type -q tmux-agent-panel; and echo ok'
```

## 実行ルール

- ユーザーが「picker で選びたい」と言うか、対象 branch が未指定なら `fish -ic 'wta'`
- ユーザーが branch 名を指定したら、そのまま `wta` に渡す
- 新規 branch 作成が必要なら `--create` を付ける
- PR/MR 番号が与えられたら `pr:{N}` / `mr:{N}` をそのまま使う
- 追加の tmux 操作はまず不要。pane 構成は `tmux-agent-panel` に委ねる

## 期待される結果

`wta` は worktrunk で対象 worktree へ切り替え、`tmux-agent-panel` を起動する。
レイアウトは以下:

- 左: coding agent
- 右上: `nvim .`
- 右下: 開発用 shell

## 失敗時

- `wta: Unknown command` の場合: fish 設定が未反映。`task apply` 後に再試行
- `wt switch` のエラー: branch 名、`--create` の要否、`gh` 認証状態を確認
- tmux 関連エラー: `tmux` のインストールと実行可否を確認
