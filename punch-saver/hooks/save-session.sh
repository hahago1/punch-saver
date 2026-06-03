#!/bin/bash
# ============================================
# punch-saver — Claude Code 会话存档脚本
# 机械保存原始 transcript，不做总结，不思考
#
# 由 hook 触发:
#   SessionStart → save-session.sh previous  (补存上次可能漏掉的)
#   Stop         → save-session.sh           (存本次)
# 手动:
#   /save 命令 → save-session.sh force       (强制存最新，忽略去重)
#
# 跨平台: Linux(GNU bash) / macOS(bash) / Windows(Git Bash)
# 依赖: bash + python3（可选，用于 MD5 和 Markdown 转换）
# ============================================

SAVE_DIR="$HOME/.claude/sessions"
LOG_FILE="$SAVE_DIR/save.log"

# 插件路径：优先用 ${CLAUDE_PLUGIN_ROOT}（安装为插件时），
# fallback 到旧路径（settings.json 手动配置时）
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
    CONVERTER="${CLAUDE_PLUGIN_ROOT}/hooks/jsonl-to-text.py"
else
    CONVERTER="$HOME/.claude/hooks/jsonl-to-text.py"
fi

RETENTION_DAYS="${SESSION_SAVER_RETENTION_DAYS:-90}"
MODE="${1:-latest}"

mkdir -p "$SAVE_DIR"

# ---- 检查 python3 是否可用 ----
HAS_PYTHON=false
command -v python3 >/dev/null 2>&1 && HAS_PYTHON=true

# ---- MD5 哈希（优先 Python，兼容 Linux/macOS/Win） ----
get_hash() {
    local f="$1"
    if $HAS_PYTHON; then
        python3 -c "import hashlib; print(hashlib.md5(open('$f','rb').read()).hexdigest())" 2>/dev/null
    elif command -v md5sum >/dev/null 2>&1; then
        md5sum "$f" 2>/dev/null | awk '{print $1}'
    elif command -v md5 >/dev/null 2>&1; then
        md5 -q "$f" 2>/dev/null
    else
        echo ""
    fi
}

# ---- 自动发现所有项目目录 ----
PROJECT_DIRS=$(ls -d "$HOME/.claude/projects/"*/ 2>/dev/null)

if [ -z "$PROJECT_DIRS" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: No project directories" >> "$LOG_FILE"
    exit 0
fi

SAVED=0

for proj_dir in $PROJECT_DIRS; do
    # 列出 JSONL 文件（排除目录，只取文件）
    jsonl_files=$(ls -t "$proj_dir"*.jsonl 2>/dev/null)
    [ -z "$jsonl_files" ] && continue

    # 选择要存档的文件
    if [ "$MODE" = "previous" ]; then
        # SessionStart: 跳过最新（正在写入的当前会话），取第二个
        TARGET=$(echo "$jsonl_files" | sed -n '2p')
    else
        # Stop 或 force: 取最新的
        TARGET=$(echo "$jsonl_files" | head -1)
    fi

    [ -z "$TARGET" ] && continue

    proj_name=$(basename "$proj_dir")
    target_hash=$(get_hash "$TARGET")
    [ -z "$target_hash" ] && continue

    # 去重：检查是否已存过相同内容的文件
    already_saved=false
    if [ "$MODE" != "force" ]; then
        for existing in "$SAVE_DIR"/*_${proj_name}.jsonl; do
            [ ! -f "$existing" ] && continue
            existing_hash=$(get_hash "$existing")
            if [ "$target_hash" = "$existing_hash" ] && [ -n "$target_hash" ]; then
                already_saved=true
                break
            fi
        done
    fi

    if $already_saved; then
        continue
    fi

    # 存档
    ts=$(date '+%Y%m%d-%H%M%S')
    save_name="${ts}_${proj_name}"

    cp "$TARGET" "$SAVE_DIR/${save_name}.jsonl"

    if $HAS_PYTHON && [ -f "$CONVERTER" ]; then
        python3 "$CONVERTER" "$TARGET" "$SAVE_DIR/${save_name}.md" 2>> "$LOG_FILE"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${MODE}] Saved: ${save_name}.jsonl + .md ($(wc -c < "$TARGET") bytes)" >> "$LOG_FILE"
    elif $HAS_PYTHON; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${MODE}] Saved: ${save_name}.jsonl (converter not found at $CONVERTER)" >> "$LOG_FILE"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${MODE}] Saved: ${save_name}.jsonl (python3 not found, skip .md)" >> "$LOG_FILE"
    fi

    SAVED=$((SAVED + 1))
done

# 清理超过 RETENTION_DAYS 天的旧存档
find "$SAVE_DIR" -name "*.jsonl" -mtime +${RETENTION_DAYS} -delete 2>/dev/null
find "$SAVE_DIR" -name "*.md" -mtime +${RETENTION_DAYS} -delete 2>/dev/null

[ "$MODE" != "previous" ] && echo "OK: saved $SAVED session(s)"
exit 0
