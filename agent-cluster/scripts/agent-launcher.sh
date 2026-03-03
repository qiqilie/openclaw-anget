#!/bin/bash
# Agent 启动器脚本
# 根据任务类型选择合适的 Agent

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$REPO_DIR/config"

# 加载 Agent 配置
AGENTS_CONFIG="$CONFIG_DIR/agents.json"

# 选择 Agent
select_agent() {
    local task_type="$1"
    
    # 默认选择 Codex
    local agent="codex"
    
    case "$task_type" in
        backend|api|bugfix|refactor)
            agent="codex"
            ;;
        frontend|ui|react|vue)
            agent="claude-code"
            ;;
        design|ui-design|css)
            agent="gemini"
            ;;
    esac
    
    echo "$agent"
}

# 启动 Agent
launch_agent() {
    local task_id="$1"
    local agent_type="${2:-codex}"
    local model="${3:-gpt-5.3-codex}"
    local task_dir="$REPO_DIR/tasks/$task_id"
    
    if [ ! -d "$task_dir" ]; then
        echo "❌ 任务目录不存在: $task_dir"
        exit 1
    fi
    
    # 创建 tmux 会话
    local session_name="agent-$task_id"
    tmux new-session -d -s "$session_name" -c "$task_dir"
    
    # 根据 Agent 类型启动
    case "$agent_type" in
        codex)
            echo "🚀 启动 Codex Agent..."
            tmux send-keys -t "$session_name" "codex" Enter
            ;;
        claude-code)
            echo "🚀 启动 Claude Code..."
            tmux send-keys -t "$session_name" "claude" Enter
            ;;
        gemini)
            echo "🚀 启动 Gemini..."
            tmux send-keys -t "$session_name" "gemini" Enter
            ;;
    esac
    
    # 更新任务状态
    local task_file="$REPO_DIR/tasks/$task_id.json"
    if [ -f "$task_file" ]; then
        node -e "
const fs = require('fs');
const task = JSON.parse(fs.readFileSync('$task_file'));
task.status = 'running';
task.agent = '$agent_type';
task.model = '$model';
task.startedAt = $(date -u +%s)000;
fs.writeFileSync('$task_file', JSON.stringify(task, null, 2));
"
    fi
    
    echo "✅ Agent 已启动: $session_name"
    echo "   查看日志: tmux attach -t $session_name"
}

# 发送消息给 Agent
send_to_agent() {
    local task_id="$1"
    local message="$2"
    local session_name="agent-$task_id"
    
    tmux send-keys -t "$session_name" "$message" Enter
}

# 主命令
case "${1:-}" in
    launch)
        local task_id="$2"
        local agent_type="${3:-codex}"
        launch_agent "$task_id" "$agent_type" "$4"
        ;;
    send)
        send_to_agent "$2" "$3"
        ;;
    select)
        select_agent "$2"
        ;;
    *)
        echo "用法: $0 launch <task_id> [agent_type] [model]"
        echo "      $0 send <task_id> <message>"
        echo "      $0 select <task_type>"
        ;;
esac
