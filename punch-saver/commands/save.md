---
description: "Force save current session transcript, skip MD5 dedup"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/hooks/save-session.sh:*)"]
---

保存当前会话 transcript 到 `~/.claude/sessions/`。
运行 `bash "${CLAUDE_PLUGIN_ROOT}/hooks/save-session.sh" force`，跳过 MD5 去重，强制保存最新的 JSONL 并转换为 Markdown。
