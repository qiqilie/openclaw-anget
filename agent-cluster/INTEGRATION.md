# Agent 集群系统 - OpenClaw 集成

这个目录包含与 OpenClaw 集成的配置文件。

## 配置说明

1. **环境变量**
   在 `.env` 文件中配置：
   ```
   GITHUB_TOKEN=your_github_token
   OPENAI_API_KEY=your_openai_key
   ANTHROPIC_API_KEY=your_anthropic_key
   GEMINI_API_KEY=your_gemini_key
   ```

2. **Cron 任务**
   设置定时任务来监控 Agent：
   ```bash
   # 每 10 分钟检查一次任务状态
   */10 * * * * /path/to/agent-cluster/scripts/monitor.sh
   ```

3. **Telegram 通知**
   配置 Telegram bot 来接收任务完成通知

## 使用方法

### 创建新任务
```bash
cd agent-cluster
./scripts/worktree-manager.sh create my-feature
./scripts/agent-launcher.sh launch my-feature codex
```

### 查看任务状态
```bash
./scripts/monitor.sh check
```

### 干预 Agent
```bash
./scripts/agent-launcher.sh send my-feature "停一下，先做API层"
```
