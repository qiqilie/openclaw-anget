# Agent 集群系统

本目录包含用于自动化软件开发的 Agent 集群系统，灵感来自 OpenClaw + Codex 架构。

## 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                     OpenClaw (编排层)                        │
│  • 持有业务上下文                                            │
│  • 理解需求并拆解任务                                         │
│  • 选择合适的 Agent                                          │
│  • 监控进度，失败时调整策略                                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Agent 执行层                             │
│  • Codex - 后端/复杂逻辑                                     │
│  • Claude Code - 前端/快速迭代                               │
│  • Gemini - UI 设计                                          │
└─────────────────────────────────────────────────────────────┘
```

## 目录结构

```
openclaw-anget/
├── .claude/                    # Claude Code 配置
│   ├── settings.json
│   └── commands/
├── .codex/                     # Codex 配置
│   └── settings.json
├── scripts/                    # 脚本目录
│   ├── worktree-manager.sh     # Git worktree 管理
│   ├── agent-launcher.sh       # Agent 启动器
│   ├── monitor.sh             
│   └── task # 任务监控-notifier.sh        # 通知脚本
├── tasks/                      # 任务记录
│   └── templates/
├── config/                     # 配置文件
│   ├── agents.json             # Agent 选择策略
│   └── prompts/                # Prompt 模板
├── logs/                       # 日志目录
└── README.md
```

## 快速开始

1. 配置 Agent API 密钥
2. 运行 `scripts/worktree-manager.sh` 创建新任务
3. 通过 OpenClaw 启动 Agent

## 成本

- 起步: ~$20/月
- 重度使用: ~$190/月
