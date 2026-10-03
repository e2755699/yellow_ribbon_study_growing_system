#!/usr/bin/env bash
# 任務看板的唯一來源是 origin/master 的 docs/task-dashboard.md。
# 任何分支、worktree 或雲端 agent 都用這支腳本讀寫，不切換分支、不碰工作目錄裡的同名檔。
#
#   tool/task_dashboard.sh pull               取最新版到草稿檔並印出路徑
#   tool/task_dashboard.sh publish "訊息"     把草稿直接提交並推到 origin/master
#   tool/task_dashboard.sh show               印出 origin/master 上的最新版
set -euo pipefail

FILE=docs/task-dashboard.md
REMOTE=origin
BRANCH=master
cd "$(git rev-parse --show-toplevel)"
DIR="$(git rev-parse --git-common-dir)/task-dashboard"
WORK="$DIR/working.md"
BASE="$DIR/base.md"
mkdir -p "$DIR"

# 以任務 ID 逐列三方合併：不同列各自生效；同一列兩邊都改才算衝突
row_merge() {
  local py=python3
  command -v python3 >/dev/null && python3 -c 'pass' 2>/dev/null || py=python
  PYTHONIOENCODING=utf-8 "$py" - "$1" "$2" "$3" <<'PY'
import re, sys
ours_p, base_p, theirs_p = sys.argv[1:4]
read = lambda p: open(p, encoding='utf-8').read().replace('\r\n', '\n').split('\n')
ours, base, theirs = read(ours_p), read(base_p), read(theirs_p)
row = re.compile(r'^\|\s*([A-Z]+-[A-Z0-9]+(?:\.\d+)*)\s*\|')
def rows(lines): return {m.group(1): l for l in lines if (m := row.match(l))}
def text(lines): return [l for l in lines if not row.match(l)]
def pick(b, o, t):
    if o == b: return t, False
    if t == b or o == t: return o, False
    return o, True
O, B, T = rows(ours), rows(base), rows(theirs)
merged, conflicts = {}, []
for k in list(T) + [k for k in O if k not in T] + [k for k in B if k not in T and k not in O]:
    v, bad = pick(B.get(k), O.get(k), T.get(k))
    if bad: conflicts.append(k)
    merged[k] = v
body, bad = pick(text(base), text(ours), text(theirs))
if bad: conflicts.append('（表格以外的文字）')
if conflicts:
    sys.stderr.write('同一處兩邊都改了：' + '、'.join(conflicts) + '\n'); sys.exit(1)
src = theirs if body == text(theirs) else ours
out, last = [], -1
for l in src:
    m = row.match(l)
    if m:
        if merged.get(m.group(1)) is not None:
            out.append(merged.pop(m.group(1))); last = len(out)
        else:
            merged.pop(m.group(1), None)
    else:
        out.append(l)
extra = [v for v in merged.values() if v is not None]
out[last:last] = extra
open(ours_p, 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
PY
}

fetch() { git fetch -q "$REMOTE" "$BRANCH"; }
remote_file() { git show "$REMOTE/$BRANCH:$FILE"; }

case "${1:-}" in
  show)
    fetch
    remote_file
    ;;
  pull)
    fetch
    remote_file > "$BASE"
    cp "$BASE" "$WORK"
    echo "$WORK"
    ;;
  publish)
    msg="${2:?需要提交訊息，例如：docs(tasks): CI-A2 → 已完成}"
    [ -f "$WORK" ] || { echo "沒有草稿，先執行 pull" >&2; exit 1; }
    for attempt in 1 2 3; do
      fetch
      remote_file > "$DIR/remote.md"
      # 別人在 pull 之後也改過：三方合併，衝突就停下讓 agent 處理
      if ! cmp -s "$DIR/remote.md" "$BASE"; then
        if ! row_merge "$WORK" "$BASE" "$DIR/remote.md"; then
          echo "與 master 上的修改衝突，請依 master 最新內容（$DIR/remote.md）重新編輯 $WORK 後再 publish" >&2
          cp "$DIR/remote.md" "$BASE"
          exit 1
        fi
        cp "$DIR/remote.md" "$BASE"
      fi
      if cmp -s "$WORK" "$DIR/remote.md"; then echo "沒有變更"; exit 0; fi
      parent="$(git rev-parse "$REMOTE/$BRANCH")"
      blob="$(git hash-object -w "$WORK")"
      export GIT_INDEX_FILE="$DIR/index"
      git read-tree "$parent"
      git update-index --cacheinfo "100644,$blob,$FILE"
      tree="$(git write-tree)"
      unset GIT_INDEX_FILE
      commit="$(git commit-tree "$tree" -p "$parent" -m "$msg")"
      if git push -q "$REMOTE" "$commit:refs/heads/$BRANCH"; then
        cp "$WORK" "$BASE"
        echo "已推到 $REMOTE/$BRANCH：$(git rev-parse --short "$commit")"
        exit 0
      fi
      echo "推送被拒（master 剛有新提交），重試 $attempt" >&2
    done
    exit 1
    ;;
  *)
    sed -n '2,8p' "$0"
    exit 2
    ;;
esac
