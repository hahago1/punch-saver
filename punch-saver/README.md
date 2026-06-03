# punch-saver 🕹️

> 机械存档 Claude Code 会话 — 像工厂流水线的打卡按钮，按一下，留一份。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 这是什么 / What

Claude Code 插件。在每次会话结束时自动保存原始 transcript（JSONL + Markdown 双格式），不做 AI 总结，不思考，纯机械复制。

**Why "punch"?** 灵感来自工厂流水线的打卡机 — 到站按一下，留一个印记。不花哨，不出错。

## 功能 / Features

- **自动存档** — Stop hook 保存最新，SessionStart hook 补存上次遗漏（覆盖 Ctrl+C 场景）
- **MD5 去重** — 相同内容不重复存
- **双格式** — JSONL（原始数据）+ Markdown（可读文本）
- **滚动清理** — 默认保留 90 天，过期自动删
- **手动触发** — `/save` 命令强制保存，跳过去重
- **跨平台** — Linux（bash）、macOS（bash）、Windows（Git Bash）

## 安装 / Install

```bash
claude plugin install hahago1/punch-saver
```

安装后即可生效，无需额外配置。存档文件在 `~/.claude/sessions/`。

## 文件说明 / Files

```
punch-saver/
├── .claude-plugin/plugin.json   # 插件元信息
├── hooks/
│   ├── hooks.json               # 声明 Stop + SessionStart 钩子
│   ├── save-session.sh           # 核心存档脚本
│   └── jsonl-to-text.py          # JSONL → Markdown 转换器
├── commands/save.md              # /save 命令
└── README.md
```

## 依赖 / Requirements

- **bash**（必需）— Linux/macOS 自带，Windows 需 Git Bash
- **python3**（可选）— 用于 Markdown 转换和跨平台 MD5。无 python3 时只存 JSONL

## 配置 / Config

| 环境变量 | 默认值 | 说明 |
|---|---|---|
| `SESSION_SAVER_RETENTION_DAYS` | `90` | 存档保留天数 |

## 许可 / License

MIT © 2026 hahago1
