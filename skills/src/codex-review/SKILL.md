---
name: codex-review
description: Codex（Coding Agent）にコードレビューを依頼する。codex exec で非対話実行し、セッション resume で再レビュー時のコンテキストを維持。Use when: 「Codexにレビュー」「codex-review」「別エージェントにレビュー」などのリクエストで使用。
allowed-tools: Bash(codex exec:*), Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(jq:*), Bash(date:*)
---

# Codex Review スキル

`codex exec` の非対話モードで Codex（Coding Agent）にコードレビューを依頼する。
`--json` で JSONL イベントストリームを取得し、`resume <session_id>` で再レビュー時のコンテキストを完全維持。
複数の AI Agent を活用し、多角的な観点でのレビューを実現する。

## レビュー出力形式

Codex の最終出力を **JSON 形式** で受け取る。`codex exec --json` の JSONL イベントストリームから `jq` パイプで抽出するため、中間ファイルは不要。

### JSON スキーマ

```json
{
  "$schema": "codex-review-output-v1",
  "status": "complete",
  "summary": "レビュー全体の一行要約",
  "findings": [
    {
      "id": 1,
      "severity": "critical|high|medium|info",
      "title": "指摘タイトル",
      "description": "問題の詳細",
      "file": "対象ファイルパス",
      "line_start": 42,
      "line_end": 45,
      "suggestion": "修正提案",
      "category": "bug|security|performance|architecture|readability"
    }
  ],
  "files_reviewed": ["ファイル一覧"],
  "review_scope": "使用した diff コマンド"
}
```

**フィールド仕様:**

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `$schema` | string | Yes | 固定値 `"codex-review-output-v1"` |
| `status` | string | Yes | `"complete"` で完了を示す |
| `summary` | string | Yes | レビュー全体の一行要約 |
| `findings` | array | Yes | 指摘の配列。問題なしの場合は空配列 `[]` |
| `findings[].id` | number | Yes | 連番（1始まり） |
| `findings[].severity` | string | Yes | `"critical"` / `"high"` / `"medium"` / `"info"` |
| `findings[].title` | string | Yes | 指摘の短いタイトル |
| `findings[].description` | string | Yes | 問題の詳細説明 |
| `findings[].file` | string | No | 対象ファイルパス |
| `findings[].line_start` | number | No | 該当開始行 |
| `findings[].line_end` | number | No | 該当終了行 |
| `findings[].suggestion` | string | Yes | 具体的な修正提案 |
| `findings[].category` | string | Yes | `"bug"` / `"security"` / `"performance"` / `"architecture"` / `"readability"` |
| `files_reviewed` | array | Yes | レビューしたファイルの一覧 |
| `review_scope` | string | Yes | 使用した diff コマンド |

## 実行フロー

### Step 1: レビュー対象の特定と変更コンテキストの整理

レビューを依頼する前に、**対象・背景・意図**を整理する。Codex が的確なレビューを行うために不可欠なステップ。

#### 1-1. レビュー対象の決定

ユーザーの指示に応じてレビュー対象を決定する。

| ユーザー指示 | レビュー対象 | 取得方法 |
|---|---|---|
| 指定なし（デフォルト） | ステージング済み + 未ステージの変更 | `git diff HEAD` |
| 「最新コミット」 | 直近のコミット | `git diff HEAD~1..HEAD` |
| 「ブランチの変更」 | ブランチ全体の差分 | `git diff main...HEAD` |
| 特定ファイル指定 | 指定ファイル | ファイルパスを直接指定 |

#### 1-2. 変更ファイル一覧の取得

diff から変更対象のファイル一覧を取得し、Codex に明示する。

```bash
# 例: デフォルトの場合
git diff HEAD --name-only
```

#### 1-3. 変更コンテキストの要約を作成

現在の会話のコンテキストから、以下を要約文として整理する。この要約をレビュープロンプトに含める。

- **何を変更したか**: 変更内容の概要（機能追加、バグ修正、リファクタリング等）
- **なぜ変更したか**: 変更の目的・動機（ユーザーの要求、問題の発見等）
- **どう判断したか**: 実装方針を選んだ理由（トレードオフ、設計判断等）
- **スコープ外**: 意図的に変更しなかった箇所があれば明記（不要な指摘を防ぐ）

**この要約は、Codex が「なぜこの変更が必要だったのか」を理解した上でレビューするために必須。** diff だけでは変更の意図が伝わらず、的外れな指摘が増える。

#### 1-4. REVIEW_ID の生成

セッション全体で使い回す一意の ID を生成する。エラー時のデバッグ識別子として使用。

```bash
REVIEW_ID="$(date +%Y%m%d%H%M%S)-$$"
```

**REVIEW_ID はこのセッション中、Step 2〜6 のループ全体で固定。**

### Step 2: レビューリクエストの送信 ← ループ開始点

> **再レビュー時は Step 6 からここに戻る。** 初回とそれ以降でプロンプト内容とコマンドが異なる（後述）。

`codex exec --json --full-auto` で Codex を非対話実行し、JSONL 出力を `jq` パイプで処理して thread_id とレビュー内容を抽出する。

**初回レビュー:**

```bash
set -o pipefail
codex exec --json --full-auto "$(cat <<'PROMPT'
<レビュープロンプト>
PROMPT
)" | jq -c '
  if .type == "thread.started" then {t:"tid", v:.thread_id}
  elif (.type == "item.completed" and .item.type == "agent_message") then {t:"review", v:.item.text}
  else empty end'
```

Bash パラメータ: `run_in_background: true`, `timeout: 600000`

**再レビュー（同一セッション resume）:**

```bash
set -o pipefail
codex exec --json --full-auto resume "$THREAD_ID" "$(cat <<'PROMPT'
<再レビュープロンプト>
PROMPT
)" | jq -c '
  if (.type == "item.completed" and .item.type == "agent_message") then {t:"review", v:.item.text}
  else empty end'
```

`resume "$THREAD_ID"` により:
- Codex は前回のレビュー内容を完全に記憶
- 何を指摘したか、Claude がどう判断したか、ユーザーがどう対応したかを把握
- 的確な再レビューが可能

**`--last` は使用しない。** 並列で別プロジェクトの Codex セッションが走っている場合にセッション衝突が起きるため、必ず明示的な `$THREAD_ID` を使用する。

**プロンプトは heredoc で渡す。** シェル引数として直接渡すと、プロンプト内のシングルクォート等でコマンドが破壊される。`"$(cat <<'PROMPT' ... PROMPT)"` 形式を使うことで、クォートや特殊文字を安全に渡せる。

**`set -o pipefail` は必須。** デフォルトではパイプラインの終了コードは最後のコマンド（`jq`）になるため、`codex exec` の失敗が握りつぶされる。`pipefail` により先頭コマンドの非ゼロ終了を検知できる。

**JSONL イベント構造:**

| イベント型 | 用途 |
|---|---|
| `thread.started` | `thread_id` を含む。セッション管理用 |
| `turn.started` | ターン開始（無視） |
| `item.completed` (`item.type == "reasoning"`) | 推論過程（無視） |
| `item.completed` (`item.type == "agent_message"`) | **最終出力テキスト（レビュー JSON）** |
| `turn.completed` | ターン完了（無視） |

### Step 3: 完了待機とレビュー結果の抽出

#### 3-1. 完了待機

`codex exec` は blocking なので、バックグラウンドタスクの完了を `TaskOutput` で待つだけ:

```
TaskOutput(task_id=<background_task_id>, block=true, timeout=600000)
```

TaskOutput の出力は jq パイプで処理済みの以下の形式:

```jsonl
{"t":"tid","v":"thread_abc123"}
{"t":"review","v":"{\"$schema\":\"codex-review-output-v1\",\"status\":\"complete\",...}"}
```

**タイムアウト時:** TaskOutput が 10 分でタイムアウトした場合、ユーザーに報告して**ループを終了する**（Step 4 には進まない）。

#### 3-2. thread_id の取得（初回のみ）

TaskOutput の出力から `"t":"tid"` の行を読み取り、`v` の値を `THREAD_ID` として保持する。再レビュー時の `resume` に使用。

#### 3-3. レビュー結果の取得（2段階）

TaskOutput の出力から `"t":"review"` の行の `v` フィールドがレビュー JSON 文字列。

**Phase 1: サマリーのみ取得**

まずサマリーと severity 別カウントだけを取得する。コンテキスト消費を最小限にする。

```bash
echo '<review JSON string>' | jq '{summary, finding_count: (.findings | length), critical: ([.findings[] | select(.severity == "critical")] | length), high: ([.findings[] | select(.severity == "high")] | length), medium: ([.findings[] | select(.severity == "medium")] | length), info: ([.findings[] | select(.severity == "info")] | length)}'
```

出力例:
```json
{
  "summary": "全体的に良好。1件のバグと2件の改善提案あり",
  "finding_count": 3,
  "critical": 0,
  "high": 1,
  "medium": 1,
  "info": 1
}
```

**Phase 2: 必要な指摘の詳細を取得**

critical/high がある場合のみ詳細を取得する:

```bash
echo '<review JSON string>' | jq '.findings[] | select(.severity == "critical" or .severity == "high")'
```

medium/info の詳細も必要な場合:

```bash
echo '<review JSON string>' | jq '.findings[]'
```

### Step 4: レビュー結果の妥当性判断

Codex から返ってきた JSON レビュー結果を精査する。**盲目的に受け入れず、必ず自分で判断する。**

#### 4-1. 指摘の分類

各指摘を以下の分類に振り分ける：

| 分類 | 条件 | 例 |
|---|---|---|
| **妥当（採用候補）** | 明らかなバグ・脆弱性の指摘 | null参照、off-by-one、XSS など |
| **不当（却下）** | 文脈の誤解、YAGNI 違反、既存規約との矛盾 | 対象外コードへの言及、過度な抽象化提案 |
| **判断材料不足** | プロジェクト固有の事情が絡み、自分だけでは判断できない | ビジネスロジック、外部制約、技術的負債 |

#### 4-2. 判断材料不足の指摘 → AskUserQuestion で情報収集

判断材料が足りない指摘がある場合、**まず AskUserQuestion でユーザーに背景情報を確認する**。

AskUserQuestion 時は以下を含める：
1. Codex の指摘内容の要約
2. 判断できない理由（どの情報が不足しているか）
3. 想定される選択肢

ユーザーの回答を得てから、その指摘を「妥当（採用候補）」か「不当（却下）」に再分類する。

#### 4-3. 指摘がゼロの場合 → ループ終了

`finding_count == 0` の場合、**Step 5 をスキップしてループを終了する**。ユーザーにレビュー完了（問題なし）を報告する。

#### 4-4. 全指摘の分類が確定したら → Step 5 へ

すべての指摘が「採用候補」または「却下」に分類できた状態で次に進む。

### Step 5: 実装方針の決定とユーザー確認

#### 5-1. 修正案の策定

採用候補の各指摘に対して、具体的な修正案を策定する：

1. 各指摘に対して**具体的な実装方法**を検討する
2. 修正が他の箇所に影響しないか確認する
3. 却下した指摘についても却下理由を整理する

#### 5-2. AskUserQuestion で修正案ごとにユーザー確認（必須）

**修正案が確定したら、必ず AskUserQuestion でユーザーに確認を取る。**自分が妥当と判断した場合でも、ユーザーの承認なしに実装に進んではならない。

**AskUserQuestion の question フィールドには改行（`\n`）を使い、読みやすく構造化すること。**1行に詰め込まない。

指摘ごとに以下のフォーマットで提示する：

```
【#番号 重要度】指摘タイトル\n
\n
問題: Codex が何を指摘したか\n
判断: 採用/却下とその理由\n
修正案: 具体的にどう直すか
```

**良い例:**
```
【#1 critical】null 参照の可能性\n
\n
問題: user オブジェクトが null の場合に user.name でクラッシュする\n
判断: 採用。入力バリデーションが不足している\n
修正案: user の null チェックを追加し、null の場合は早期リターンする
```

**悪い例:**
```
【#1 critical】null 参照の可能性。user が null でクラッシュ。修正案: null チェック追加
```

ユーザーの判断を受けて、最終的な実装方針を確定する。

### Step 6: 修正の実装 → 再レビュー or 終了

Step 5 でユーザーが承認した方針に基づきコードを修正する。

#### 分岐: 再レビューが必要か判定

| 条件 | アクション |
|---|---|
| 実際にコード修正を行った | **Step 2 に戻って再レビュー**。`resume "$THREAD_ID"` で同一セッション維持。再レビュープロンプトに判断経緯とコンテキストを含める |
| 全指摘が「対応しない」とユーザーが判断し、コード修正がない | **ループ終了**。再レビュー不要 |

#### ループの終了条件

以下のいずれかを満たした場合にループを終了する：
- Codex から**指摘がゼロ**（Step 4-3 で即終了）
- Codex から新たな **critical / high** の指摘がない（残りが **medium / info のみ** → ユーザーに報告するが対応は任意。ループは終了する）
- ユーザーが全指摘を「対応しない」と判断し、コード変更がない
- **TaskOutput がタイムアウト**した（10分経過）→ ユーザーに報告して**ループを終了する**（Step 4 には進まない）

終了時はユーザーにレビュー完了を報告する。

```
レビューループ:
Step 2 (codex exec) → Step 3 (TaskOutput待機 + 抽出) → Step 4 (妥当性判断) → Step 5 (ユーザー確認) → Step 6 (修正)
  ↑                          |                          |                                                      |
  │                      タイムアウト                指摘ゼロ                                                     |
  │                          ↓                        ↓                                                       |
  ├────── コード修正あり → Step 2 へ戻る（resume $THREAD_ID で再レビュー）─────────────────────────────────────────┘
  │
  終了 ← critical/high の新規指摘なし or 全指摘「対応しない」でコード変更なし
```

## レビュープロンプトのテンプレート

`"$(cat <<'PROMPT' ... PROMPT)"` 形式の heredoc でシェル引数として渡す。クォートや特殊文字のエスケープ処理は不要。

### 初回レビュー（デフォルト: git diff）

**Step 1-3 で作成した変更コンテキスト要約を `[変更コンテキスト]` に埋め込むこと。**

```
以下の変更をレビューしてください。

変更の背景: [変更コンテキスト: 何を・なぜ・どう判断して変更したかの要約]
変更ファイル: [1-2 で取得したファイル一覧]
スコープ外: [意図的に変更しなかった箇所があれば記載]

差分は git diff HEAD で確認してください。

レビュー観点:
1. バグ・ロジックエラー
2. セキュリティ脆弱性
3. パフォーマンス問題
4. 設計・アーキテクチャの改善点
5. 可読性・保守性

【重要: 出力形式】
レビュー結果を以下の JSON 形式で出力してください。JSON のみを出力し、説明文やマークダウンは不要です。

JSON スキーマ: {"$schema":"codex-review-output-v1","status":"complete","summary":"レビュー全体の一行要約","findings":[{"id":1,"severity":"critical|high|medium|info","title":"指摘タイトル","description":"問題の詳細","file":"対象ファイルパス","line_start":行番号,"line_end":行番号,"suggestion":"修正提案","category":"bug|security|performance|architecture|readability"}],"files_reviewed":["ファイル一覧"],"review_scope":"使用したdiffコマンド"}

severity の基準:
- critical: 致命的問題（必ず修正）
- high: 高優先度（強く推奨）
- medium: 中優先度（推奨）
- info: 情報・質問

指摘がない場合は findings を空配列 [] にしてください。
必ず status を "complete" に設定してください。
```

### 初回レビュー（特定ファイル）

```
以下のファイルをレビューしてください: [ファイルパス]

変更の背景: [変更コンテキスト: 何を・なぜ・どう判断して変更したかの要約]
スコープ外: [意図的に変更しなかった箇所があれば記載]

レビュー観点: 1.バグ・ロジックエラー 2.セキュリティ脆弱性 3.パフォーマンス問題 4.設計・アーキテクチャの改善点

【重要: 出力形式】レビュー結果を以下の JSON 形式で出力してください。JSON のみを出力し、説明文やマークダウンは不要です。スキーマ: {"$schema":"codex-review-output-v1","status":"complete","summary":"一行要約","findings":[{"id":1,"severity":"critical|high|medium|info","title":"タイトル","description":"詳細","file":"パス","line_start":行,"line_end":行,"suggestion":"提案","category":"bug|security|performance|architecture|readability"}],"files_reviewed":["一覧"],"review_scope":"対象"}。指摘なしは findings:[]。必ず status:"complete" を設定。
```

### 再レビュー（2回目以降）

以下のテンプレートの各セクションを実際の内容で埋めて `codex exec resume "$THREAD_ID"` に渡すこと。

```
前回のレビュー指摘を受けて修正しました。再レビューをお願いします。前回の指摘と対応: [各指摘の要約・判断・対応内容を列挙]。ユーザーとの協議事項: [AskUserQuestion で確認した質問・回答・反映内容]。修正差分は git diff HEAD で確認してください。再レビュー観点: 1.前回指摘が適切に修正されているか 2.修正で新たな問題が発生していないか 3.見落としがないか。【重要: 出力形式】レビュー結果を以下の JSON 形式で出力してください。JSON のみを出力し、説明文やマークダウンは不要です。スキーマ: {"$schema":"codex-review-output-v1","status":"complete","summary":"一行要約","findings":[{"id":1,"severity":"critical|high|medium|info","title":"タイトル","description":"詳細","file":"パス","line_start":行,"line_end":行,"suggestion":"提案","category":"bug|security|performance|architecture|readability"}],"files_reviewed":["一覧"],"review_scope":"対象"}。指摘なしは findings:[]。必ず status:"complete" を設定。
```

## エラーハンドリング

| エラー状況 | 対処 |
|---|---|
| codex exec がタイムアウト | TaskOutput のタイムアウトで検知。ユーザーに報告してループ終了 |
| codex exec が非ゼロ終了 | `set -o pipefail` により検知。TaskOutput の出力に stderr のエラー情報が含まれる。ユーザーに報告 |
| jq パイプの出力が空 | JSONL イベント構造が想定と異なる可能性。`codex exec --json --full-auto "echo test" \| jq -c '.type'` で実際のイベント型を確認し、jq フィルタを調整する |
| レビュー JSON が不正（パースエラー） | jq バリデーションで検知。ユーザーに報告 |
| codex CLI 未インストール | エラーを報告しインストール案内 |
| jq 未インストール | jq は必須。エラーを報告してユーザーに `nix-env -iA nixpkgs.jq` 等でのインストールを案内する |

## 利用例

### 基本的な使い方
```
ユーザー: Codex にレビューして
→ git diff HEAD の変更をレビュー依頼
```

### ブランチ全体のレビュー
```
ユーザー: Codex にこのブランチの変更をレビューして
→ git diff main...HEAD の変更をレビュー依頼
```

### 特定ファイル
```
ユーザー: Codex に src/auth.ts をレビューして
→ 指定ファイルのレビュー依頼
```
