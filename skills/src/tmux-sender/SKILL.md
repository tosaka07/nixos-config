---
name: tmux-sender
description: tmux の別ペインにコマンドを送信する。「ペインで実行して」「tmuxで送信」などのリクエストで使用。
allowed-tools: Bash(tmux:*)
---

# tmux コマンド送信スキル

## 使い方

tmux のペインにコマンドを送信して実行する場合：

```bash
tmux send-keys -t <ペイン番号> '<コマンド>'
sleep 0.5
tmux send-keys -t <ペイン番号> Enter
```

## 重要: テキストと Enter は必ず分離する

テキストと Enter を同じ `send-keys` で送ると、TUI アプリ（Codex 等）はペースト操作として一括受信し、Enter が改行文字として処理されてしまう。必ず別の `send-keys` コールで Enter を送ること。

```bash
# NG: テキストとEnterを同時送信（ペーストとして扱われる）
tmux send-keys -t <ペイン番号> 'プロンプト' Enter

# OK: テキストとEnterを分離（キーストロークとして扱われる）
tmux send-keys -t <ペイン番号> 'プロンプト'
sleep 0.5
tmux send-keys -t <ペイン番号> Enter
```

## 手順

1. `tmux list-panes` でペイン一覧を確認
2. `tmux send-keys -t <ペイン番号> '<コマンド>'` でテキストを送信
3. `sleep 0.5` で待機
4. `tmux send-keys -t <ペイン番号> Enter` で確定・実行