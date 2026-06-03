#!/usr/bin/env python3
"""
Claude Code transcript JSONL → Markdown 转换
机械转换，无 AI 参与
用法: python3 jsonl-to-text.py <input.jsonl> <output.md>
"""
import json, sys
from datetime import datetime

def load(path):
    events = []
    with open(path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                events.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return events

def fmt_ts(ms):
    if not ms:
        return ""
    try:
        return datetime.fromtimestamp(ms / 1000).strftime("%Y-%m-%d %H:%M:%S")
    except:
        return ""

def render(events):
    out = []
    out.append("# 会话记录\n")
    out.append(f"**转换时间**：{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    out.append(f"**消息数**：{len(events)}\n")
    out.append("---\n\n")

    for e in events:
        t = e.get("type", "")
        ts = fmt_ts(e.get("timestamp"))

        if t == "user":
            msg = e.get("message", {}).get("content", "")
            if isinstance(msg, list):
                texts = [b.get("text", "") for b in msg if b.get("type") == "text"]
                msg = "\n".join(texts)
            out.append(f"## 用户 {ts}\n\n{msg}\n\n")

        elif t == "assistant":
            blocks = e.get("message", {}).get("content", [])
            for block in blocks:
                if block.get("type") == "text":
                    out.append(f"## Claude {ts}\n\n{block.get('text', '')}\n\n")
                elif block.get("type") == "tool_use":
                    name = block.get("name", "?")
                    inp = json.dumps(block.get("input", {}), ensure_ascii=False)
                    out.append(f"### 🔧 {name} {ts}\n\n```json\n{inp}\n```\n\n")

        elif t == "user-message":
            msg = e.get("content", "")
            if isinstance(msg, list):
                texts = [b.get("text", "") for b in msg if isinstance(b, dict) and b.get("type") == "text"]
                msg = "\n".join(texts)
            out.append(f"## 用户 {ts}\n\n{msg}\n\n")

        elif t == "tool_result":
            content = e.get("content", "")
            if isinstance(content, list):
                content = "".join([c.get("text", "") if isinstance(c, dict) else str(c) for c in content])
            if isinstance(content, str) and len(content) > 3000:
                content = content[:3000] + f"\n\n... (截断，原 {len(content)} 字符)"
            out.append(f"### 📋 工具返回 `{e.get('tool_use_id', '')}`\n\n```\n{content}\n```\n\n")

    return "\n".join(out)

def main():
    if len(sys.argv) < 2:
        print(f"用法: {sys.argv[0]} <input.jsonl> [output.md]")
        sys.exit(1)

    inp = sys.argv[1]
    out = sys.argv[2] if len(sys.argv) > 2 else inp.rsplit(".", 1)[0] + ".md"

    events = load(inp)
    md = render(events)

    with open(out, 'w', encoding='utf-8') as f:
        f.write(md)

    print(f"OK: {out} ({len(events)} events)")

if __name__ == "__main__":
    main()
