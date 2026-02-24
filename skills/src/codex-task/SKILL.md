---
name: codex-task
description: Codex に任意のタスクを委譲して実行。codex exec で非対話実行し resume でコンテキスト維持。Use when: 「Codexに〇〇して」「codex-task」「Codexに任せて」「別エージェントに〇〇させて」
allowed-tools: Bash(codex exec:*), Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(jq:*), Bash(date:*)
---

# Codex Task スキル

`codex exec` の非対話モードで Codex（Coding Agent）に任意のタスクを委譲する。
`--json` で JSONL イベントストリームを取得し、`resume <session_id>` で追加指示時のコンテキストを完全維持。
jq は JSONL トランスポート（thread_id・出力テキスト抽出）にのみ使用。

## 実行フロー

### Step 1: タスクの整理とプロンプト作成

ユーザーの指示を Codex が正確に実行できる形に整理する。

#### 1-1. タスク内容の明確化

ユーザーの指示が曖昧な場合は **AskUserQuestion で確認**してから進む。以下を整理:

- **何をするか**: タスクの具体的な内容
- **対象**: どのファイル・ディレクトリ・コード範囲か
- **制約**: やってほしくないこと、スコープ外の事項
- **成功条件**: どうなったら完了か

#### 1-2. 現在の状態を把握

タスクに応じて必要な情報を取得する:

```bash
git status --porcelain        # 変更状態
git diff HEAD --name-only     # 変更ファイル
git log --oneline -5          # 直近コミット
```

#### 1-3. プロンプトの組み立て

以下の構造でプロンプトを作成する:

```
タスク: [具体的な指示]
対象: [ファイル・ディレクトリ等]
背景: [なぜこのタスクが必要か。会話コンテキストから要約]
制約: [スコープ外・やらないこと]
完了条件: [何をもって完了とするか]
```

**プロンプトには会話から得たコンテキスト（変更の意図、設計判断、ユーザーの好み等）を必ず含める。** Codex は会話の文脈を知らないため、必要な情報をすべてプロンプトに埋め込む。

### Step 2: タスクの送信 ← ループ開始点

> **追加指示時は Step 5 からここに戻る。**

`codex exec --json --full-auto` で Codex を非対話実行し、JSONL 出力を `jq` パイプで処理。

`run_in_background: true`, `timeout: 600000` で実行。プロンプトは **heredoc** で渡す（クォート破壊防止）。`set -o pipefail` 必須（codex exec 失敗検知）。

**初回実行:**

```bash
set -o pipefail
codex exec --json --full-auto "$(cat <<'PROMPT'
<タスクプロンプト>
PROMPT
)" | jq -c '
  if .type == "thread.started" then {t:"tid", v:.thread_id}
  elif (.type == "item.completed" and .item.type == "agent_message") then {t:"result", v:.item.text}
  else empty end'
```

**追加指示（同一セッション resume）:**

```bash
set -o pipefail
codex exec --json --full-auto resume "$THREAD_ID" "$(cat <<'PROMPT'
<追加指示プロンプト>
PROMPT
)" | jq -c '
  if (.type == "item.completed" and .item.type == "agent_message") then {t:"result", v:.item.text}
  else empty end'
```

`resume "$THREAD_ID"` により Codex は前回の作業内容・ファイル変更・判断を完全に記憶。

**`--last` は使用しない。** 並列セッション衝突回避のため、必ず明示的な `$THREAD_ID` を使用する。

### Step 3: 完了待機と結果の抽出

#### 3-1. 完了待機

```
TaskOutput(task_id=<background_task_id>, block=true, timeout=600000)
```

TaskOutput の出力は jq パイプで処理済みの形式:

```jsonl
{"t":"tid","v":"thread_abc123"}
{"t":"result","v":"Codex の出力テキスト"}
```

**タイムアウト時:** ユーザーに報告してループを終了する。

#### 3-2. thread_id の取得（初回のみ）

`"t":"tid"` の行から `v` の値を `THREAD_ID` として保持。追加指示の `resume` に使用。

#### 3-3. 結果の取得

`"t":"result"` の行の `v` フィールドが Codex の出力テキスト。

### Step 4: 結果の検証とユーザー報告

#### 4-1. Codex の作業結果を検証

Codex がファイルを変更した場合:

```bash
git diff HEAD --stat           # 変更の概要
git diff HEAD                  # 詳細な差分
```

以下を確認する:
- タスクの要件を満たしているか
- 意図しない変更がないか
- 明らかなバグ・問題がないか

#### 4-2. ユーザーに結果を報告

Codex の出力テキストと検証結果をまとめてユーザーに報告する:

1. **タスク完了状況**: 成功/部分成功/失敗
2. **変更内容**: Codex が何をしたか（ファイル変更がある場合は差分の要約）
3. **問題点**: 検証で見つかった問題があれば指摘
4. **次のアクション提案**: 追加修正・コミット・レビュー等

#### 4-3. 問題がない場合 → ループ終了

タスクが正常に完了し、追加の指示がなければループを終了する。

### Step 5: 追加指示 → 再実行 or 終了

ユーザーが追加の修正や調整を求めた場合:

| 条件 | アクション |
|---|---|
| 追加指示あり | **Step 2 に戻る**。`resume "$THREAD_ID"` で同一セッション維持。追加指示プロンプトに経緯を含める |
| 問題をこちらで修正 | Claude が直接修正し、必要なら再度 Codex に検証を依頼 |
| タスク完了 | **ループ終了** |

#### ループの終了条件

- タスクが正常に完了し、ユーザーが承認
- ユーザーが追加指示なしと判断
- **TaskOutput がタイムアウト**（10分経過）→ ユーザーに報告してループ終了

```
タスクループ:
Step 2 (codex exec) → Step 3 (TaskOutput待機 + 抽出) → Step 4 (検証・報告) → Step 5 (追加指示判定)
  ↑                          |                                                        |
  │                      タイムアウト                                                    |
  │                          ↓                                                         |
  ├────── 追加指示あり → Step 2 へ戻る（resume $THREAD_ID）──────────────────────────────┘
  │
  終了 ← タスク完了 or ユーザー承認
```

## プロンプトテンプレート

### 初回実行

```
以下のタスクを実行してください。

タスク: [具体的な指示]
対象: [ファイル・ディレクトリ]
背景: [コンテキスト要約]
制約: [スコープ外・やらないこと]
完了条件: [成功基準]

作業内容と結果を報告してください。
```

### 追加指示（resume）

```
前回のタスクに追加指示があります。
追加内容: [追加の指示]
経緯: [前回の結果と今回の追加理由]
作業内容と結果を報告してください。
```

## エラーハンドリング

| エラー状況 | 対処 |
|---|---|
| codex exec がタイムアウト | TaskOutput のタイムアウトで検知。ユーザーに報告してループ終了 |
| codex exec が非ゼロ終了 | `set -o pipefail` により検知。ユーザーに報告 |
| jq パイプの出力が空 | JSONL イベント構造が想定と異なる可能性。`codex exec --json --full-auto "echo test" \| jq -c '.type'` でイベント型を確認しフィルタ調整 |
| codex CLI 未インストール | エラーを報告しインストール案内 |
| jq 未インストール | jq は必須（JSONL パース用）。インストール案内 |
