---
name: codex-review
description: tmux ペインの Codex にコードレビューを依頼する。Codex がいない場合は新規ペインを作成・起動してからレビューを依頼する。複数 Coding Agent による多角的レビューを実現。Use when: 「Codexにレビュー」「codex-review」「別エージェントにレビュー」などのリクエストで使用。
allowed-tools: Bash(tmux:*), Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(sleep:*), Bash(cat /tmp/codex-review*), Bash(rm /tmp/codex-review*), Bash(jq:*), Bash(test:*), Bash(date:*), Bash(until jq*codex-review*)
---

# Codex Review スキル

tmux の別ペインで動作する Codex（Coding Agent）にコードレビューを依頼する。
複数の AI Agent を活用し、多角的な観点でのレビューを実現する。

## レビュー出力形式

Codex にはレビュー結果を **JSON ファイル** (`/tmp/codex-review-{id}.json`) に書き出させる。
ターミナルへの直接出力ではなく構造化ファイルを使うことで、コンテキスト消費を最小限に抑える。

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

### Step 1: tmux セッション確認

```bash
tmux list-panes -F '#{pane_index}:#{pane_current_command}:#{pane_pid}' 2>/dev/null
```

tmux 内で実行されていない場合はエラーを報告して終了する。

### Step 2: Codex ペインの検出

自ペインを除外した上で、codex が動作中のペインを検出する。**プロセス名チェックを優先し、画面テキスト検索はフォールバックとして使用する。**

```bash
# 自ペインの番号を取得
MY_PANE=$(tmux display-message -p '#{pane_index}')

# 全ペインを走査（自ペインを除外）
for pane_id in $(tmux list-panes -F '#{pane_index}'); do
  [ "$pane_id" = "$MY_PANE" ] && continue

  # 優先: プロセス名の検索
  cmd=$(tmux list-panes -F '#{pane_index}:#{pane_current_command}' | grep "^${pane_id}:" | cut -d: -f2)
  if echo "$cmd" | grep -qi 'codex'; then
    echo "FOUND:$pane_id"
    break
  fi

  # フォールバック: 画面テキストの検索
  content=$(tmux capture-pane -t "$pane_id" -p 2>/dev/null | tail -20)
  if echo "$content" | grep -qi 'codex'; then
    echo "FOUND:$pane_id"
    break
  fi
done
```

**判定の優先順位:**
1. **自ペインを除外**（誤検出防止）
2. **プロセス名に `codex` が含まれる**（最も確実）
3. **画面テキストに `codex` が含まれる**（フォールバック）

### Step 3-A: Codex が見つからない場合 → 新規ペイン作成

```bash
# 現在のペイン番号を記録
CURRENT_PANE=$(tmux display-message -p '#{pane_index}')

# 右側に新しいペインを作成し、ペインIDを取得（-P で新ペインの情報を出力）
NEW_PANE=$(tmux split-window -h -c "#{pane_current_path}" -P -F '#{pane_index}')

# 新しいペインで codex を起動
tmux send-keys -t "$NEW_PANE" 'codex'
sleep 0.5
tmux send-keys -t "$NEW_PANE" Enter

# 元のペインにフォーカスを戻す
tmux select-pane -t "$CURRENT_PANE"

# Codex の起動を待つ
sleep 5
```

`$NEW_PANE` が Codex ペインの番号として以降のステップで使用される。

### Step 3-B: Codex が見つかった場合

検出したペイン番号をそのまま使用する。

### Step 4: レビュー対象の特定と変更コンテキストの整理

レビューを依頼する前に、**対象・背景・意図**を整理する。Codex が的確なレビューを行うために不可欠なステップ。

#### 4-1. レビュー対象の決定

ユーザーの指示に応じてレビュー対象を決定する。

| ユーザー指示 | レビュー対象 | 取得方法 |
|---|---|---|
| 指定なし（デフォルト） | ステージング済み + 未ステージの変更 | `git diff HEAD` |
| 「最新コミット」 | 直近のコミット | `git diff HEAD~1..HEAD` |
| 「ブランチの変更」 | ブランチ全体の差分 | `git diff main...HEAD` |
| 特定ファイル指定 | 指定ファイル | ファイルパスを直接指定 |

#### 4-2. 変更ファイル一覧の取得

diff から変更対象のファイル一覧を取得し、Codex に明示する。

```bash
# 例: デフォルトの場合
git diff HEAD --name-only
```

#### 4-3. 変更コンテキストの要約を作成

現在の会話のコンテキストから、以下を要約文として整理する。この要約をレビュープロンプトに含める。

- **何を変更したか**: 変更内容の概要（機能追加、バグ修正、リファクタリング等）
- **なぜ変更したか**: 変更の目的・動機（ユーザーの要求、問題の発見等）
- **どう判断したか**: 実装方針を選んだ理由（トレードオフ、設計判断等）
- **スコープ外**: 意図的に変更しなかった箇所があれば明記（不要な指摘を防ぐ）

**この要約は、Codex が「なぜこの変更が必要だったのか」を理解した上でレビューするために必須。** diff だけでは変更の意図が伝わらず、的外れな指摘が増える。

#### 4-4. REVIEW_ID の生成

セッション全体で使い回す一意の ID を生成する。再レビューでも同じ ID を使用する。

```bash
REVIEW_ID="$(date +%Y%m%d%H%M%S)-$$"
REVIEW_FILE="/tmp/codex-review-${REVIEW_ID}.json"
echo "REVIEW_FILE=${REVIEW_FILE}"
```

**REVIEW_ID はこのセッション中、Step 5〜9 のループ全体で固定。** 再レビュー時に新しい ID を生成しない。

### Step 5: レビューリクエストの送信 ← ループ開始点

> **再レビュー時は Step 9 からここに戻る。** 初回とそれ以降でプロンプト内容が異なる（後述）。

#### 5-1. 前回の結果ファイルを削除（再レビュー時）

再レビュー時は、前回のファイルが残っていると polling が即座に完了と判定してしまうため、送信前に削除する。

```bash
rm -f "$REVIEW_FILE"
```

**ワイルドカード (`/tmp/codex-review-*.json`) は使用しない。** 他セッションのファイルを壊さないように、自セッションのファイルだけを削除する。

#### 5-2. プロンプト送信

tmux send-keys でレビュー依頼プロンプトを Codex ペインに送信する。

**重要: テキストと Enter は必ず別の send-keys コールで送信する。**
同時に送ると TUI アプリがペースト操作として一括受信し、Enter が改行文字として処理されてしまう。

```bash
# OK: テキストとEnterを分離
tmux send-keys -t <CODEX_PANE> '<レビュープロンプト>'
sleep 0.5
tmux send-keys -t <CODEX_PANE> Enter
```

```bash
# NG: テキストとEnterを同時送信（ペーストとして扱われる）
tmux send-keys -t <CODEX_PANE> '<レビュープロンプト>' Enter
```

### Step 6: Polling でレビュー完了を待機

Codex のレビュー完了を **JSON ファイルの存在チェック** で検知する。**コンテキスト消費を避けるため、Bash の `run_in_background` で実行する。**

**ワンライナー（`<REVIEW_FILE>` は Step 4-4 の値に置換）:**

```bash
until jq -e '.status=="complete"' <REVIEW_FILE> 2>/dev/null; do sleep 15; done; echo REVIEW_READY
```

Bash ツールのパラメータ:
- `run_in_background: true`
- `timeout: 600000`（10分）

**polling の仕様:**
- **実行方法**: Bash ツールの `run_in_background: true` を使用し、メインコンテキストを消費しない
- **チェック間隔**: 15秒（ファイル存在チェックは軽量）
- **完了判定**: `jq -e '.status=="complete"'` が成功した時点
- **タイムアウト**: Bash ツールの `timeout: 600000` で制御。超過時はタスク出力に timeout エラーが記録される
- **結果取得**: `TaskOutput` で `REVIEW_READY` を確認後、Step 7 へ進む

**タイムアウト時のフォールバック:**

polling がタイムアウトした場合（`REVIEW_READY` が出力されない）、Codex ペインの最新状態を確認してユーザーに報告する:

```bash
tmux capture-pane -t <CODEX_PANE> -p | tail -30
```

### Step 7: レビュー結果の妥当性判断

Codex から返ってきた JSON レビュー結果を精査する。**盲目的に受け入れず、必ず自分で判断する。**

#### 7-0. 2段階読み取り（コンテキスト節約）

**Phase 1: サマリーのみ取得**

まずサマリーと severity 別カウントだけを取得する。コンテキスト消費を最小限にする。

```bash
jq '{summary, finding_count: (.findings | length), critical: ([.findings[] | select(.severity == "critical")] | length), high: ([.findings[] | select(.severity == "high")] | length), medium: ([.findings[] | select(.severity == "medium")] | length), info: ([.findings[] | select(.severity == "info")] | length)}' "$REVIEW_FILE"
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
jq '.findings[] | select(.severity == "critical" or .severity == "high")' "$REVIEW_FILE"
```

medium/info の詳細も必要な場合:

```bash
cat "$REVIEW_FILE"
```

#### 7-1. 指摘の分類

各指摘を以下の分類に振り分ける：

| 分類 | 条件 | 例 |
|---|---|---|
| **妥当（採用候補）** | 明らかなバグ・脆弱性の指摘 | null参照、off-by-one、XSS など |
| **不当（却下）** | 文脈の誤解、YAGNI 違反、既存規約との矛盾 | 対象外コードへの言及、過度な抽象化提案 |
| **判断材料不足** | プロジェクト固有の事情が絡み、自分だけでは判断できない | ビジネスロジック、外部制約、技術的負債 |

#### 7-2. 判断材料不足の指摘 → AskUserQuestion で情報収集

判断材料が足りない指摘がある場合、**まず AskUserQuestion でユーザーに背景情報を確認する**。

AskUserQuestion 時は以下を含める：
1. Codex の指摘内容の要約
2. 判断できない理由（どの情報が不足しているか）
3. 想定される選択肢

ユーザーの回答を得てから、その指摘を「妥当（採用候補）」か「不当（却下）」に再分類する。

#### 7-3. 指摘がゼロの場合 → ループ終了

`finding_count == 0` の場合、**Step 8 をスキップしてループを終了する**。ユーザーにレビュー完了（問題なし）を報告する。

#### 7-4. 全指摘の分類が確定したら → Step 8 へ

すべての指摘が「採用候補」または「却下」に分類できた状態で次に進む。

### Step 8: 実装方針の決定とユーザー確認

#### 8-1. 修正案の策定

採用候補の各指摘に対して、具体的な修正案を策定する：

1. 各指摘に対して**具体的な実装方法**を検討する
2. 修正が他の箇所に影響しないか確認する
3. 却下した指摘についても却下理由を整理する

#### 8-2. AskUserQuestion で修正案ごとにユーザー確認（必須）

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

### Step 9: 修正の実装 → 再レビュー or 終了

Step 8 でユーザーが承認した方針に基づきコードを修正する。

#### 分岐: 再レビューが必要か判定

| 条件 | アクション |
|---|---|
| 実際にコード修正を行った | **Step 5 に戻って再レビュー**。再レビュープロンプトに判断経緯とコンテキストを含める |
| 全指摘が「対応しない」とユーザーが判断し、コード修正がない | **ループ終了**。再レビュー不要 |

#### ループの終了条件

以下のいずれかを満たした場合にループを終了する：
- Codex から**指摘がゼロ**（Step 7-3 で即終了）
- Codex から新たな **critical / high** の指摘がない（残りが **medium / info のみ** → ユーザーに報告するが対応は任意。ループは終了する）
- ユーザーが全指摘を「対応しない」と判断し、コード変更がない
- **Polling がタイムアウト**した（10分経過）→ ユーザーに報告して**ループを終了する**（Step 7 には進まない）

#### ループ終了時のクリーンアップ

```bash
rm -f "$REVIEW_FILE"
```

終了時はユーザーにレビュー完了を報告する。

```
レビューループ:
Step 5 (送信) → Step 6 (polling待機) → Step 7 (妥当性判断) → Step 8 (ユーザー確認) → Step 9 (修正)
  ↑                                  |                |                                      |
  │                              タイムアウト      指摘ゼロ                                    |
  │                                  ↓              ↓                                       |
  ├────── コード修正あり → Step 5 へ戻る（再レビュー）──────────────────────────────────────────┘
  │
  終了 ← critical/high の新規指摘なし or 全指摘「対応しない」でコード変更なし
```

## レビュープロンプトのテンプレート

送信するプロンプトは以下の形式で構成する。
**重要: tmux send-keys で送信するため、プロンプトはシングルクォートで囲み、内部のシングルクォートはエスケープする。**

### 初回レビュー（デフォルト: git diff）

**Step 4-3 で作成した変更コンテキスト要約を `[変更コンテキスト]` に埋め込むこと。**
**`<REVIEW_FILE>` は Step 4-4 で生成した実際のファイルパスに置き換えること。**

```
以下の変更をレビューしてください。

変更の背景: [変更コンテキスト: 何を・なぜ・どう判断して変更したかの要約]
変更ファイル: [4-2 で取得したファイル一覧]
スコープ外: [意図的に変更しなかった箇所があれば記載]

差分は git diff HEAD で確認してください。

レビュー観点:
1. バグ・ロジックエラー
2. セキュリティ脆弱性
3. パフォーマンス問題
4. 設計・アーキテクチャの改善点
5. 可読性・保守性

【重要: 出力形式】
レビュー結果を以下の JSON 形式で <REVIEW_FILE> に書き出してください。ターミナルへのレビュー出力は不要です。ファイルへの書き出しのみ行ってください。

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

【重要: 出力形式】レビュー結果を JSON 形式で <REVIEW_FILE> に書き出してください。ターミナルへの出力は不要です。スキーマ: {"$schema":"codex-review-output-v1","status":"complete","summary":"一行要約","findings":[{"id":1,"severity":"critical|high|medium|info","title":"タイトル","description":"詳細","file":"パス","line_start":行,"line_end":行,"suggestion":"提案","category":"bug|security|performance|architecture|readability"}],"files_reviewed":["一覧"],"review_scope":"対象"}。指摘なしは findings:[]。必ず status:"complete" を設定。
```

### 再レビュー（2回目以降）

tmux send-keys で直接送信する。以下のテンプレートの各セクションを実際の内容で埋めて送信すること。

```
前回のレビュー指摘を受けて修正しました。再レビューをお願いします。前回の指摘と対応: [各指摘の要約・判断・対応内容を列挙]。ユーザーとの協議事項: [AskUserQuestion で確認した質問・回答・反映内容]。修正差分は git diff HEAD で確認してください。再レビュー観点: 1.前回指摘が適切に修正されているか 2.修正で新たな問題が発生していないか 3.見落としがないか。【重要: 出力形式】レビュー結果を JSON 形式で <REVIEW_FILE> に書き出してください。ターミナルへの出力は不要です。スキーマ: {"$schema":"codex-review-output-v1","status":"complete","summary":"一行要約","findings":[{"id":1,"severity":"critical|high|medium|info","title":"タイトル","description":"詳細","file":"パス","line_start":行,"line_end":行,"suggestion":"提案","category":"bug|security|performance|architecture|readability"}],"files_reviewed":["一覧"],"review_scope":"対象"}。指摘なしは findings:[]。必ず status:"complete" を設定。
```

```bash
tmux send-keys -t <CODEX_PANE> '<上記テンプレートを埋めたプロンプト>'
sleep 0.5
tmux send-keys -t <CODEX_PANE> Enter
```

## tmux send-keys の注意事項

### プロンプトは直接 send-keys で送る

プロンプトは tmux send-keys で直接ペインに送信する。一時ファイルを経由する必要はない。

### エスケープ処理

- シングルクォート `'` → `'\''` に置換
- バッククォート `` ` `` → エスケープまたは避ける
- `$` → リテラルとして送りたい場合はエスケープ

## エラーハンドリング

| エラー状況 | 対処 |
|---|---|
| Codex が JSON でなくテキストで出力した | ポーリングタイムアウト後、フォールバックで pane 出力を確認しユーザーに報告 |
| JSON ファイルが不正（パースエラー） | `jq` がエラーを返すためポーリング継続。タイムアウト後にユーザーに報告 |
| ファイルが一切作成されない | タイムアウト後に pane を確認し、Codex の状態をユーザーに報告 |
| jq が未インストール | jq は必須。エラーを報告してユーザーに `nix-env -iA nixpkgs.jq` 等でのインストールを案内する |

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
