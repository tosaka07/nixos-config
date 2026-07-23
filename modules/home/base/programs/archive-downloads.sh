# archive-downloads — ~/Downloads の中身を日付付き ZIP にまとめて ~/Archives/Downloads に保存する。
#
# Usage:
#   archive-downloads            ZIP を作成する(元ファイルは残す)。
#   archive-downloads --delete   ZIP 作成後、元ファイルを削除する。
#   archive-downloads -o DIR     保存先ディレクトリを指定する(デフォルト: ~/Archives/Downloads)。
#   archive-downloads -y         .dmg/.zip や 100MB 以上のファイルの確認をせず、すべて含める。
#   archive-downloads --help     ヘルプを表示する。
#
# .dmg/.zip ファイルや 100MB 以上のファイルは、含めるかどうかを1件ずつ対話的に確認する
# (標準入力が端末でない場合は確認せずすべて含める)。

SOURCE_DIR="$HOME/Downloads"
DEST_DIR="$HOME/Archives/Downloads"
DELETE_AFTER=0
ASSUME_YES=0
LARGE_FILE_THRESHOLD_BYTES=$(( 100 * 1024 * 1024 ))

print_help() {
  cat <<'USAGE'
archive-downloads — ~/Downloads の中身を日付付き ZIP にまとめて保存する

Usage:
  archive-downloads            ZIP を作成する(元ファイルは残る)。
  archive-downloads --delete   ZIP 作成後、元ファイルを削除する。
  archive-downloads -o DIR     保存先ディレクトリを指定する(デフォルト: ~/Archives/Downloads)。
  archive-downloads -y         確認せず、対象ファイルをすべて含める。
  archive-downloads -h|--help  このヘルプを表示する。

.dmg/.zip ファイルや 100MB 以上のファイルは、含めるかどうかを1件ずつ確認する
(標準入力が端末でない場合は確認せずすべて含める)。
USAGE
}

while (( $# > 0 )); do
  case "$1" in
    -h|--help)
      print_help
      exit 0
      ;;
    -d|--delete)
      DELETE_AFTER=1
      shift
      ;;
    -y|--yes)
      ASSUME_YES=1
      shift
      ;;
    -o|--output)
      if (( $# < 2 )); then
        echo "archive-downloads: $1 には DIR 引数が必要です" >&2
        exit 2
      fi
      DEST_DIR="$2"
      shift 2
      ;;
    --output=*)
      DEST_DIR="${1#--output=}"
      shift
      ;;
    *)
      echo "archive-downloads: 不明な引数です: $1" >&2
      echo "'archive-downloads --help' で使い方を確認してください。" >&2
      exit 2
      ;;
  esac
done

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "archive-downloads: $SOURCE_DIR が見つかりません" >&2
  exit 1
fi

shopt -s nullglob dotglob
entries=("$SOURCE_DIR"/*)
shopt -u nullglob dotglob

if (( ${#entries[@]} == 0 )); then
  echo "archive-downloads: $SOURCE_DIR は空です。何もしません。"
  exit 0
fi

human_size() {
  local bytes="$1"
  awk -v b="$bytes" 'BEGIN {
    units[0]="B"; units[1]="KB"; units[2]="MB"; units[3]="GB"; units[4]="TB"
    i = 0
    while (b >= 1024 && i < 4) { b /= 1024; i++ }
    printf "%.1f%s", b, units[i]
  }'
}

# .dmg/.zip や 100MB 以上のファイルを検出し、対話的に含めるか確認する。
# 除外されたファイルは EXCLUDE_PATTERNS (SOURCE_DIR からの相対パス) に積む。
EXCLUDE_PATTERNS=()

interactive=0
if [[ -t 0 ]]; then
  interactive=1
fi

while IFS= read -r -d '' file; do
  relpath="${file#"$SOURCE_DIR"/}"
  size_bytes="$(stat -f%z "$file" 2>/dev/null || echo 0)"
  reason=""
  case "$relpath" in
    *.[Zz][Ii][Pp]) reason="zip" ;;
    *.[Dd][Mm][Gg]) reason="dmg" ;;
  esac
  if (( size_bytes >= LARGE_FILE_THRESHOLD_BYTES )); then
    if [[ -n "$reason" ]]; then
      reason="$reason, 100MB以上"
    else
      reason="100MB以上"
    fi
  fi
  [[ -z "$reason" ]] && continue

  size_human="$(human_size "$size_bytes")"

  if (( ASSUME_YES )) || (( ! interactive )); then
    if (( ! interactive )) && (( ! ASSUME_YES )); then
      echo "archive-downloads: 非対話実行のため確認せず含めます: $relpath ($size_human, $reason)"
    fi
    continue
  fi

  read -r -p "archive-downloads: $relpath ($size_human, $reason) をZIPに含めますか? [Y/n] " answer </dev/tty || answer="y"
  case "$answer" in
    [Nn]*)
      EXCLUDE_PATTERNS+=("$relpath")
      ;;
  esac
done < <(find "$SOURCE_DIR" -type f \( -iname '*.zip' -o -iname '*.dmg' -o -size +100M \) -print0)

mkdir -p "$DEST_DIR"

today="$(date +%Y-%m-%d)"
archive_path="$DEST_DIR/downloads-$today.zip"
suffix=1
while [[ -e "$archive_path" ]]; do
  archive_path="$DEST_DIR/downloads-$today-$suffix.zip"
  suffix=$(( suffix + 1 ))
done

if (( ${#EXCLUDE_PATTERNS[@]} > 0 )); then
  echo "archive-downloads: 以下のファイルを除外します:"
  printf '  - %s\n' "${EXCLUDE_PATTERNS[@]}"
fi

echo "archive-downloads: $SOURCE_DIR を $archive_path にまとめています..."
(
  cd "$SOURCE_DIR"
  zip -r -X -q "$archive_path" . -x ".DS_Store" "${EXCLUDE_PATTERNS[@]}"
)
echo "archive-downloads: 作成しました -> $archive_path"

if (( DELETE_AFTER )); then
  if (( ${#EXCLUDE_PATTERNS[@]} > 0 )); then
    echo "archive-downloads: 除外したファイルは残し、ZIPに含めたファイルのみ削除します..."
    while IFS= read -r -d '' file; do
      relpath="${file#"$SOURCE_DIR"/}"
      excluded=0
      for ex in "${EXCLUDE_PATTERNS[@]}"; do
        if [[ "$relpath" == "$ex" ]]; then
          excluded=1
          break
        fi
      done
      (( excluded )) && continue
      rm -f "$file"
    done < <(find "$SOURCE_DIR" -type f -print0)
    find "$SOURCE_DIR" -mindepth 1 -type d -empty -delete
  else
    echo "archive-downloads: $SOURCE_DIR の中身を削除しています..."
    find "$SOURCE_DIR" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
  fi
  echo "archive-downloads: 削除しました"
fi
