#!/usr/bin/env bash
# awake — ふたを閉じても Mac をスリープさせないための補助コマンド。
#
# Usage:
#   awake                  フォアグラウンド実行。Ctrl+C で解除して終了。
#   awake -t 1h            1時間後に自動停止するフォアグラウンド実行。
#   awake -b 20            バッテリー残量が 20% 以下になったら自動停止。
#   awake start            バックグラウンドで実行(シェルを閉じても継続)。
#   awake start -t 1h      タイムアウト付きバックグラウンド実行。
#   awake status           実行状態を表示。
#   awake stop             バックグラウンド実行を停止。
#   awake --help           ヘルプを表示。

set -u

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "awake: macOS でのみ動作します" >&2
  exit 1
fi

STATE_DIR="${AWAKE_STATE_DIR:-$HOME/.local/state/awake}"
PID_FILE="$STATE_DIR/awake.pid"
DEADLINE_FILE="$STATE_DIR/awake.deadline"
BATTERY_FILE="$STATE_DIR/awake.battery"
LOG_FILE="$STATE_DIR/awake.log"

BATTERY_POLL_SECS=60

print_help() {
  cat <<'USAGE'
awake — ふたを閉じても Mac をスリープさせないための補助コマンド

Usage:
  awake                  フォアグラウンド実行。Ctrl+C で解除して終了。
  awake -t DURATION      DURATION 後に自動停止するフォアグラウンド実行。
  awake -b PERCENT       バッテリー残量が PERCENT% 以下になったら自動停止。
  awake start            バックグラウンドで実行(detached)。シェルを閉じても継続。
  awake start -t DURATION -b PERCENT
                         時間/バッテリー条件付きのバックグラウンド実行。
  awake status           実行状態・PID・稼働時間・pmset disablesleep を表示。
  awake stop             バックグラウンド実行を停止し、スリープ設定を復元。
  awake -h|--help        このヘルプを表示。

Duration (-t / --timeout):
  h/m/s を組み合わせて指定 (例: 1h, 30m, 45s, 1h30m, 2h15m30s)。
  数字のみの場合は秒として扱う (`-t 3600` == `-t 1h`)。

Battery threshold (-b / --battery):
  1-99 の整数。バッテリー駆動時にこの値以下になったら自動停止する。
  60秒間隔でチェックし、AC電源時はスキップする。

  -t と -b は併用可能で、先に条件を満たした方で停止する。

State files:
  PID file:      $HOME/.local/state/awake/awake.pid
  Deadline file: $HOME/.local/state/awake/awake.deadline
  Battery file:  $HOME/.local/state/awake/awake.battery
  Log file:      $HOME/.local/state/awake/awake.log
  (AWAKE_STATE_DIR で上書き可能)

Behavior:
  - `pmset -a disablesleep 1` (sudo) でクラムシェルスリープを無効化
  - `caffeinate -is` でシステムアイドルスリープを防止
  - sudo は起動時に一度だけ要求される。その認証で常駐する root ヘルパーが、
    Ctrl+C・SIGTERM・タイムアウト・バッテリー閾値・SIGKILL のいずれで
    awake が終了しても `disablesleep 0` に復元する(終了時に再度のsudoなし)。
USAGE
}

parse_battery_threshold() {
  local input="${1%\%}"
  if [[ ! "$input" =~ ^[0-9]+$ ]]; then
    return 1
  fi
  if (( input < 1 || input > 99 )); then
    return 1
  fi
  printf '%s' "$input"
}

battery_percent() {
  local out
  out="$(pmset -g batt 2>/dev/null || true)"
  printf '%s' "$out" | awk '
    match($0, /[0-9]+%/) {
      pct = substr($0, RSTART, RLENGTH - 1)
      print pct
      exit
    }
  '
}

power_source() {
  local out
  out="$(pmset -g batt 2>/dev/null || true)"
  printf '%s' "$out" | awk '
    /Now drawing from/ {
      if (index($0, "AC Power")) { print "ac"; exit }
      if (index($0, "Battery Power")) { print "battery"; exit }
    }
  '
}

parse_duration() {
  local input="$1"
  if [[ -z "$input" ]]; then
    return 1
  fi
  if [[ "$input" =~ ^[0-9]+$ ]]; then
    if (( input <= 0 )); then
      return 1
    fi
    printf '%s' "$input"
    return 0
  fi
  if [[ ! "$input" =~ ^([0-9]+h)?([0-9]+m)?([0-9]+s)?$ ]]; then
    return 1
  fi
  local h="${BASH_REMATCH[1]%h}"
  local m="${BASH_REMATCH[2]%m}"
  local s="${BASH_REMATCH[3]%s}"
  h="${h:-0}"; m="${m:-0}"; s="${s:-0}"
  local total=$(( h * 3600 + m * 60 + s ))
  if (( total <= 0 )); then
    return 1
  fi
  printf '%s' "$total"
}

pmset_disablesleep_value() {
  local out
  out="$(pmset -g 2>/dev/null || true)"
  printf '%s' "$out" | awk '/SleepDisabled/ {print $2; exit}'
}

is_running() {
  local pid="$1"
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

read_pid() {
  [[ -f "$PID_FILE" ]] || return 1
  local pid
  pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  printf '%s' "$pid"
}

# バックグラウンドで走っていないとき、PIDファイルを持たないフォアグラウンド
# 実行(別シェル)を pmset assertions 経由の caffeinate 親から逆引きする。
find_foreground_awake_pids() {
  local caff_pids
  caff_pids="$(pmset -g assertions 2>/dev/null | awk 'match($0, /pid [0-9]+\(caffeinate\)/) {
      s = substr($0, RSTART + 4, RLENGTH - 4)
      sub(/\(.*/, "", s)
      print s
    }' | sort -u || true)"
  [[ -z "$caff_pids" ]] && return 0

  local cpid ppid pcmd
  local self_pid="$$"
  while read -r cpid; do
    [[ -z "$cpid" ]] && continue
    ppid="$(ps -o ppid= -p "$cpid" 2>/dev/null | tr -d ' ' || true)"
    [[ -z "$ppid" || "$ppid" == "1" ]] && continue
    pcmd="$(ps -o command= -p "$ppid" 2>/dev/null || true)"
    if [[ "$pcmd" == *"/awake"* || "$pcmd" == *" awake "* || "$pcmd" == *" awake" ]]; then
      [[ "$pcmd" == *"__detached"* ]] && continue
      [[ "$ppid" == "$self_pid" ]] && continue
      printf '%s\n' "$ppid"
    fi
  done <<<"$caff_pids"
}

process_uptime_secs() {
  local pid="$1"
  local raw
  raw="$(ps -o etime= -p "$pid" 2>/dev/null | awk '{$1=$1; print}' || true)"
  [[ -z "$raw" ]] && return 1

  local days=0 hms="$raw"
  if [[ "$hms" == *-* ]]; then
    days="${hms%%-*}"
    hms="${hms#*-}"
  fi

  local h=0 m=0 s=0
  case "$hms" in
    *:*:*)
      h="${hms%%:*}"
      hms="${hms#*:}"
      m="${hms%%:*}"
      s="${hms#*:}"
      ;;
    *:*)
      m="${hms%%:*}"
      s="${hms#*:}"
      ;;
    *)
      return 1
      ;;
  esac

  days=$(( 10#${days} ))
  h=$(( 10#${h} ))
  m=$(( 10#${m} ))
  s=$(( 10#${s} ))

  printf '%s' "$(( days * 86400 + h * 3600 + m * 60 + s ))"
}

format_uptime() {
  local secs="$1"
  local d=$(( secs / 86400 ))
  local h=$(( (secs % 86400) / 3600 ))
  local m=$(( (secs % 3600) / 60 ))
  local s=$(( secs % 60 ))
  if (( d > 0 )); then
    printf '%dd %02dh %02dm %02ds' "$d" "$h" "$m" "$s"
  elif (( h > 0 )); then
    printf '%dh %02dm %02ds' "$h" "$m" "$s"
  elif (( m > 0 )); then
    printf '%dm %02ds' "$m" "$s"
  else
    printf '%ds' "$s"
  fi
}

# ---------- フォアグラウンド実行の本体 ----------

run_foreground() {
  local mode="${1:-attached}"
  local timeout_secs="${2:-0}"
  local battery_threshold="${3:-0}"

  CAFFEINATE_PID=""
  TIMER_PID=""
  BATTERY_PID=""
  HELPER_PID=""
  HELPER_FIFO=""
  HELPER_STATUS=""
  HELPER_FD_OPEN=0
  DISABLED_SLEEP=0

  cleanup() {
    trap - INT TERM HUP EXIT

    if [[ -n "$TIMER_PID" ]] && kill -0 "$TIMER_PID" 2>/dev/null; then
      kill "$TIMER_PID" 2>/dev/null || true
      wait "$TIMER_PID" 2>/dev/null || true
    fi

    if [[ -n "$BATTERY_PID" ]] && kill -0 "$BATTERY_PID" 2>/dev/null; then
      kill "$BATTERY_PID" 2>/dev/null || true
      wait "$BATTERY_PID" 2>/dev/null || true
    fi

    if [[ -n "$CAFFEINATE_PID" ]] && kill -0 "$CAFFEINATE_PID" 2>/dev/null; then
      kill "$CAFFEINATE_PID" 2>/dev/null || true
      wait "$CAFFEINATE_PID" 2>/dev/null || true
    fi

    if [[ "$DISABLED_SLEEP" -eq 1 ]]; then
      echo ""
      echo "awake: スリープ設定を復元します (root ヘルパー; sudo 再要求なし)"
    fi

    if [[ "$HELPER_FD_OPEN" -eq 1 ]]; then
      exec 9>&-
      HELPER_FD_OPEN=0
    fi
    if [[ -n "$HELPER_PID" ]]; then
      wait "$HELPER_PID" 2>/dev/null || true
    fi
    if [[ -n "$HELPER_FIFO" ]]; then
      rm -f "$HELPER_FIFO" "$HELPER_STATUS"
    fi

    if [[ "$DISABLED_SLEEP" -eq 1 && "$(pmset_disablesleep_value)" == "1" ]]; then
      echo "awake: root ヘルパーが復元できなかったため、sudo にフォールバックします" >&2
      sudo -n pmset -a disablesleep 0 \
        || sudo pmset -a disablesleep 0 \
        || echo "awake: pmset の復元に失敗しました。手動で実行してください: sudo pmset -a disablesleep 0" >&2
    fi

    if [[ "$mode" == "detached" ]]; then
      rm -f "$PID_FILE" "$DEADLINE_FILE" "$BATTERY_FILE"
    fi
  }

  trap cleanup INT TERM HUP EXIT

  mkdir -p "$STATE_DIR"

  # root ヘルパー: 一度の sudo 認証で「有効化」と「終了時の復元」の両方をカバーする。
  # ヘルパーは disablesleep を有効化した後、この awake プロセスだけが書き込み側を
  # 持つ FIFO を読み続けてブロックする。awake がどんな理由(Ctrl+C, SIGTERM,
  # タイムアウト, バッテリー閾値, SIGKILL さえも)で終了しても FIFO が EOF になり、
  # ヘルパーが root権限のまま disablesleep=0 に復元する。
  HELPER_FIFO="$STATE_DIR/helper.$$.fifo"
  HELPER_STATUS="$STATE_DIR/helper.$$.status"
  rm -f "$HELPER_FIFO" "$HELPER_STATUS"
  if ! mkfifo -m 600 "$HELPER_FIFO"; then
    echo "awake: FIFO の作成に失敗しました: $HELPER_FIFO" >&2
    exit 1
  fi
  exec 9<>"$HELPER_FIFO"
  HELPER_FD_OPEN=1

  echo "awake: スリープを無効化します (sudo のパスワードを求められる場合があります。終了時は不要です)"
  sudo bash -c '
    fifo="$1" status="$2"
    trap "" INT TERM HUP
    exec 0<"$fifo"
    if ! pmset -a disablesleep 1; then
      echo failed > "$status"
      exit 1
    fi
    echo ok > "$status"
    caff="" timer="" battery=""
    while read -r line; do
      case "$line" in
        caffeinate=*) caff="${line#caffeinate=}" ;;
        timer=*) timer="${line#timer=}" ;;
        battery=*) battery="${line#battery=}" ;;
      esac
    done
    pmset -a disablesleep 0
    if [ -n "$caff" ]; then
      kill "$caff" 2>/dev/null || true
    fi
    if [ -n "$timer" ]; then
      kill "$timer" 2>/dev/null || true
    fi
    if [ -n "$battery" ]; then
      kill "$battery" 2>/dev/null || true
    fi
    echo "awake: スリープ設定を復元しました (pmset -a disablesleep 0)"
    rm -f "$fifo" "$status"
  ' _ "$HELPER_FIFO" "$HELPER_STATUS" 9>&- &
  HELPER_PID=$!

  local pm_status="" helper_stat=""
  while :; do
    pm_status="$(cat "$HELPER_STATUS" 2>/dev/null || true)"
    [[ -n "$pm_status" ]] && break
    helper_stat="$(ps -o stat= -p "$HELPER_PID" 2>/dev/null | tr -d ' ' || true)"
    if [[ -z "$helper_stat" || "$helper_stat" == Z* ]]; then
      break
    fi
    sleep 0.1
  done
  if [[ "$pm_status" != "ok" ]]; then
    echo "awake: pmset の設定に失敗しました" >&2
    exit 1
  fi
  DISABLED_SLEEP=1

  caffeinate -is 9>&- &
  CAFFEINATE_PID=$!
  echo "caffeinate=$CAFFEINATE_PID" >&9

  local parent=$$

  if (( timeout_secs > 0 )); then
    local deadline=$(( $(date +%s) + timeout_secs ))
    if [[ "$mode" == "detached" ]]; then
      echo "$deadline" > "$DEADLINE_FILE"
    fi
    (
      sleep "$timeout_secs"
      kill -TERM "$parent" 2>/dev/null || true
    ) 9>&- &
    TIMER_PID=$!
    echo "timer=$TIMER_PID" >&9
  fi

  if (( battery_threshold > 0 )); then
    if [[ "$mode" == "detached" ]]; then
      echo "$battery_threshold" > "$BATTERY_FILE"
    fi
    (
      while sleep "$BATTERY_POLL_SECS"; do
        src="$(power_source)"
        if [[ "$src" != "battery" ]]; then
          continue
        fi
        pct="$(battery_percent)"
        if [[ -z "$pct" ]]; then
          continue
        fi
        if (( pct <= battery_threshold )); then
          echo "awake: バッテリーが ${pct}% (<= ${battery_threshold}%) になったため停止します" >&2
          kill -TERM "$parent" 2>/dev/null || true
          exit 0
        fi
      done
    ) 9>&- &
    BATTERY_PID=$!
    echo "battery=$BATTERY_PID" >&9
  fi

  local startup_msg="awake: 実行中 (PID=$$, caffeinate PID=$CAFFEINATE_PID"
  if (( timeout_secs > 0 )); then
    startup_msg+=", timeout=$(format_uptime "$timeout_secs")"
  fi
  if (( battery_threshold > 0 )); then
    startup_msg+=", battery<=${battery_threshold}%"
  fi
  startup_msg+=")"
  echo "$startup_msg"
  echo "awake: ふたを閉じても Mac はスリープしません。Ctrl+C で解除して終了します。"

  while kill -0 "$CAFFEINATE_PID" 2>/dev/null; do
    wait "$CAFFEINATE_PID" 2>/dev/null
  done
}

# ---------- サブコマンド ----------

cmd_start() {
  local timeout_secs="${1:-0}"
  local battery_threshold="${2:-0}"
  mkdir -p "$STATE_DIR"

  local pid
  if pid="$(read_pid)" && is_running "$pid"; then
    echo "awake: すでに実行中です (PID=$pid)。先に 'awake stop' してください。" >&2
    exit 1
  fi
  rm -f "$PID_FILE" "$DEADLINE_FILE" "$BATTERY_FILE"

  echo "awake: sudo 認証を先に行います (パスワードを求められる場合があります)"
  sudo -v || { echo "awake: sudo 認証に失敗しました" >&2; exit 1; }

  nohup "$0" __detached "$timeout_secs" "$battery_threshold" >>"$LOG_FILE" 2>&1 </dev/null &
  local child=$!
  disown "$child" 2>/dev/null || true

  local waited=0
  while (( waited < 30 )); do
    if pid="$(read_pid)" && is_running "$pid"; then
      echo "awake: バックグラウンドで開始しました (PID=$pid)"
      if (( timeout_secs > 0 )); then
        echo "awake: $(format_uptime "$timeout_secs") 後に自動停止します"
      fi
      if (( battery_threshold > 0 )); then
        echo "awake: バッテリーが ${battery_threshold}% (バッテリー駆動時) になったら自動停止します"
      fi
      echo "awake: ログ -> $LOG_FILE"
      echo "awake: 'awake stop' で停止できます"
      return 0
    fi
    sleep 0.1
    waited=$(( waited + 1 ))
  done

  echo "awake: バックグラウンドプロセスが正常に開始しませんでした。$LOG_FILE を確認してください" >&2
  exit 1
}

cmd_detached() {
  local timeout_secs="${1:-0}"
  local battery_threshold="${2:-0}"
  mkdir -p "$STATE_DIR"
  echo "$$" > "$PID_FILE"
  run_foreground detached "$timeout_secs" "$battery_threshold"
}

cmd_status() {
  local pid="" running=0
  if pid="$(read_pid)" && is_running "$pid"; then
    running=1
  elif [[ -f "$PID_FILE" ]]; then
    echo "awake: 古い PID ファイルが残っています ($PID_FILE, プロセスは実行されていません)"
  fi

  local disablesleep
  disablesleep="$(pmset_disablesleep_value)"
  disablesleep="${disablesleep:-unknown}"

  if (( running )); then
    local now uptime started_epoch
    now="$(date +%s)"
    uptime="$(process_uptime_secs "$pid" || true)"

    echo "awake: 実行中 (バックグラウンド)"
    echo "  pid:                $pid"
    if [[ -n "$uptime" ]]; then
      started_epoch=$(( now - uptime ))
      echo "  started:            $(date -r "$started_epoch" "+%Y-%m-%d %H:%M:%S %Z")"
      echo "  uptime:             $(format_uptime "$uptime")"
    fi
    if [[ -f "$DEADLINE_FILE" ]]; then
      local deadline remaining
      deadline="$(cat "$DEADLINE_FILE" 2>/dev/null || true)"
      if [[ "$deadline" =~ ^[0-9]+$ ]]; then
        remaining=$(( deadline - now ))
        echo "  auto-stop at:       $(date -r "$deadline" "+%Y-%m-%d %H:%M:%S %Z")"
        if (( remaining > 0 )); then
          echo "  remaining:          $(format_uptime "$remaining")"
        else
          echo "  remaining:          (deadline 超過; まもなく停止します)"
        fi
      fi
    fi
    if [[ -f "$BATTERY_FILE" ]]; then
      local threshold pct src
      threshold="$(cat "$BATTERY_FILE" 2>/dev/null || true)"
      if [[ "$threshold" =~ ^[0-9]+$ ]]; then
        pct="$(battery_percent)"
        src="$(power_source)"
        echo "  battery threshold:  ${threshold}% (now ${pct:-?}%, source: ${src:-unknown})"
      fi
    fi
    echo "  pmset disablesleep: $disablesleep"
    echo "  log:                $LOG_FILE"
  else
    local fg_pids
    fg_pids="$(find_foreground_awake_pids)"

    if [[ -n "$fg_pids" ]]; then
      local fg_pid started_epoch now uptime fg_count=0 total
      now="$(date +%s)"
      total="$(printf '%s\n' "$fg_pids" | grep -c . || true)"

      if [[ "$total" == "1" ]]; then
        echo "awake: 実行中 (別シェルでフォアグラウンド実行)"
      else
        echo "awake: 実行中 (他 $total シェルでフォアグラウンド実行)"
      fi

      while read -r fg_pid; do
        [[ -z "$fg_pid" ]] && continue
        fg_count=$(( fg_count + 1 ))
        if [[ "$total" != "1" ]]; then
          echo "  --- instance $fg_count ---"
        fi
        echo "  pid:                $fg_pid"
        uptime="$(process_uptime_secs "$fg_pid" || true)"
        if [[ -n "$uptime" ]]; then
          started_epoch=$(( now - uptime ))
          echo "  started:            $(date -r "$started_epoch" "+%Y-%m-%d %H:%M:%S %Z")"
          echo "  uptime:             $(format_uptime "$uptime")"
        fi
      done <<<"$fg_pids"
      echo "  pmset disablesleep: $disablesleep"
      echo "  stop with:          起動したシェルで Ctrl+C (または 'kill -TERM <pid>')"
    else
      echo "awake: 実行されていません (バックグラウンド)"
      echo "  pmset disablesleep: $disablesleep"
      if [[ "$disablesleep" == "1" ]]; then
        echo "  warning: disablesleep が 1 のままですが、awake プロセスは追跡されていません。"
        echo "  他のツールが保持しているか、以前の awake が強制終了された可能性があります。"
        echo "  確認: pmset -g assertions"
        echo "  復元: sudo pmset -a disablesleep 0"
      fi
    fi
  fi
}

restore_disablesleep_if_stuck() {
  local reason="$1"
  local disablesleep
  disablesleep="$(pmset_disablesleep_value)"
  [[ "$disablesleep" == "1" ]] || return 0

  echo "awake: pmset disablesleep がまだ 1 です${reason:+ ($reason)}; 復元します"
  echo "awake: スリープ設定を復元します (sudo pmset -a disablesleep 0)"
  sudo -n pmset -a disablesleep 0 \
    || sudo pmset -a disablesleep 0 \
    || echo "awake: pmset の復元に失敗しました。手動で実行してください: sudo pmset -a disablesleep 0" >&2
}

cmd_stop() {
  local pid
  if ! pid="$(read_pid)"; then
    echo "awake: PID ファイルがありません ($PID_FILE) — 停止対象なし"
    restore_disablesleep_if_stuck "追跡している awake プロセスなし"
    exit 1
  fi

  if ! is_running "$pid"; then
    echo "awake: PID $pid は実行されていません — 古い PID ファイルを削除します"
    rm -f "$PID_FILE" "$DEADLINE_FILE" "$BATTERY_FILE"
    restore_disablesleep_if_stuck "前回の実行が強制終了された可能性"
    exit 0
  fi

  echo "awake: PID $pid を停止します"
  kill -TERM "$pid" 2>/dev/null || { echo "awake: kill に失敗しました" >&2; exit 1; }

  local waited=0
  while (( waited < 50 )); do
    if ! is_running "$pid"; then
      echo "awake: 停止しました"
      return 0
    fi
    sleep 0.1
    waited=$(( waited + 1 ))
  done

  echo "awake: SIGTERM で終了しなかったため SIGKILL を送ります"
  kill -KILL "$pid" 2>/dev/null || true
  rm -f "$PID_FILE" "$DEADLINE_FILE" "$BATTERY_FILE"
  restore_disablesleep_if_stuck "cleanup trap が実行されなかった"
}

# ---------- 引数の解析とディスパッチ ----------

SUBCMD=""
TIMEOUT_RAW=""
BATTERY_RAW=""
DETACHED_TIMEOUT_SECS=""
DETACHED_BATTERY_THRESHOLD=""

while (( $# > 0 )); do
  case "$1" in
    -h|--help)
      print_help
      exit 0
      ;;
    -t|--timeout)
      if (( $# < 2 )); then
        echo "awake: $1 には DURATION 引数が必要です (例: 1h, 30m, 90s, 3600)" >&2
        exit 2
      fi
      TIMEOUT_RAW="$2"
      shift 2
      ;;
    --timeout=*)
      TIMEOUT_RAW="${1#--timeout=}"
      shift
      ;;
    -t*)
      TIMEOUT_RAW="${1#-t}"
      shift
      ;;
    -b|--battery)
      if (( $# < 2 )); then
        echo "awake: $1 には PERCENT 引数が必要です (整数 1-99)" >&2
        exit 2
      fi
      BATTERY_RAW="$2"
      shift 2
      ;;
    --battery=*)
      BATTERY_RAW="${1#--battery=}"
      shift
      ;;
    -b*)
      BATTERY_RAW="${1#-b}"
      shift
      ;;
    fg|foreground|start|status|stop)
      if [[ -n "$SUBCMD" ]]; then
        echo "awake: 予期しない追加引数です: $1" >&2
        exit 2
      fi
      SUBCMD="$1"
      shift
      ;;
    __detached)
      SUBCMD="__detached"
      shift
      DETACHED_TIMEOUT_SECS="${1:-0}"
      shift || true
      DETACHED_BATTERY_THRESHOLD="${1:-0}"
      shift || true
      ;;
    *)
      echo "awake: 不明な引数です: $1" >&2
      echo "'awake --help' で使い方を確認してください。" >&2
      exit 2
      ;;
  esac
done

TIMEOUT_SECS=0
if [[ -n "$TIMEOUT_RAW" ]]; then
  if ! TIMEOUT_SECS="$(parse_duration "$TIMEOUT_RAW")"; then
    echo "awake: 不正な duration です: '$TIMEOUT_RAW' (1h, 30m, 45s, 1h30m、または正の整数秒を指定してください)" >&2
    exit 2
  fi
fi

BATTERY_THRESHOLD=0
if [[ -n "$BATTERY_RAW" ]]; then
  if ! BATTERY_THRESHOLD="$(parse_battery_threshold "$BATTERY_RAW")"; then
    echo "awake: 不正な battery threshold です: '$BATTERY_RAW' (1-99 の整数。% 付きも可)" >&2
    exit 2
  fi
fi

case "$SUBCMD" in
  ""|fg|foreground)
    run_foreground attached "$TIMEOUT_SECS" "$BATTERY_THRESHOLD"
    ;;
  start)
    cmd_start "$TIMEOUT_SECS" "$BATTERY_THRESHOLD"
    ;;
  status)
    cmd_status
    ;;
  stop)
    cmd_stop
    ;;
  __detached)
    cmd_detached "$DETACHED_TIMEOUT_SECS" "$DETACHED_BATTERY_THRESHOLD"
    ;;
esac
