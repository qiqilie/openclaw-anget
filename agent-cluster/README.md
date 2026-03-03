# Agent 集群系统

基于 OpenClaw + Codex/Claude Code 架构的 AI Agent 集群系统，专为 Vue3 + Node.js 项目设计。

## 技术栈

- **前端**: Vue 3 + Vite + Pinia + TypeScript
- **后端**: Node.js + Express/Koa
- **AI Agent**: Codex, Claude Code, Gemini

## 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/qiqilie/openclaw-anget.git
cd openclaw-anget
```

### 2. 安装依赖

```bash
# 前端
cd frontend && pnpm install

# 后端
cd server && pnpm install
```

### 3. 配置环境

```bash
cp agent-cluster/.env.example agent-cluster/.env
# 编辑 .env 填入你的 API keys
```

### 4. 配置 Agent

确保你有以下 API 访问权限：
- **Codex**: OpenAI API Key
- **Claude Code**: Anthropic API Key  
- **Gemini**: Google AI API Key

### 5. 创建第一个任务

```bash
cd agent-cluster

# 创建新任务 (会自动创建 git worktree)
./scripts/worktree-manager.sh create feat-new-feature

# 启动 Agent
./scripts/agent-launcher.sh launch feat-new-feature
```

## 使用方法

### 任务管理

```bash
# 列出所有任务
./scripts/worktree-manager.sh list

# 创建任务
./scripts/worktree-manager.sh create feat-user-login

# 移除任务
./scripts/worktree-manager.sh remove feat-user-login
```

### Agent 控制

```bash
# 启动 Agent (会自动选择合适的类型)
./scripts/agent-launcher.sh launch <task_id>

# 发送消息给 Agent
./scripts/agent-launcher.sh send <task_id> "停一下，先做API层"

# 查看 Agent 输出
tmux attach -t agent-<task_id>
```

### 监控

```bash
# 手动检查任务状态
./scripts/monitor.sh check

# 设置 cron 任务 (每 10 分钟检查)
*/10 * * * * cd /path/to/agent-cluster && ./scripts/monitor.sh
```

## Agent 选择策略

| 任务类型 | 推荐 Agent | 说明 |
|---------|-----------|------|
| 后端 API | Codex | 擅长复杂逻辑和数据库 |
| 前端 Vue | Claude Code | 擅长 TypeScript 和组件 |
| UI 设计 | Gemini | 擅长样式和动画 |
| Bug 修复 | Codex | 擅长调试和分析 |

## 工作流程

```
客户需求
    │
    ▼
┌─────────────────┐
│  OpenClaw      │ ◄── 理解需求，拆解任务
│  (编排层)       │
└─────────────────┘
    │
    ▼
┌─────────────────┐
│  选择 Agent    │ ◄── 根据任务类型选择
└─────────────────┘
    │
    ▼
┌─────────────────┐
│  创建 Worktree  │ ◄── 隔离分支环境
└─────────────────┘
    │
    ▼
┌─────────────────┐
│  启动 Agent    │ ◄── Codex/Claude/Gemini
└─────────────────┘
    │
    ▼
┌─────────────────┐
│  监控进度       │ ◄── cron 检查 + 自动重试
└─────────────────┘
    │
    ▼
┌─────────────────┐
│  创建 PR        │ ◄── AI Code Review
└─────────────────┘
    │
    ▼
   合并
```

## 成本估算

| 使用量 | 估计成本 |
|-------|---------|
| 轻度 ($20/月) | 少量任务测试 |
| 中度 ($50/月) | 每天几个任务 |
| 重度 ($190/月) | 高强度开发 |

## 目录结构

```
openclaw-anget/
├── frontend/                 # Vue3 前端
│   ├── src/
│   │   ├── components/      # 组件
│   │   ├── views/            # 页面
│   │   ├── stores/           # Pinia
│   │   └── api/              # API
│   └── package.json
├── server/                   # Node.js 后端
│   ├── src/
│   │   ├── controllers/
│   │   ├── services/
│   │   └── routes/
│   └── package.json
└── agent-cluster/            # Agent 集群系统
    ├── scripts/              # 管理脚本
    ├── config/               # 配置文件
    ├── tasks/                # 任务记录
    └── logs/                 # 日志
```

## 注意事项

1. **内存限制**: 每个 Agent 需要独立环境，16GB RAM 最多同时跑 4-5 个
2. **安全边界**: Agent 只能访问自己的 worktree，不能接触生产数据
3. **人工 Review**: 所有 PR 需要人工审核后才能合并
