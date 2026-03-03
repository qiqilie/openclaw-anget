#!/bin/bash
# 任务监控脚本
# 每 10 分钟检查所有 Agent 状态

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
TASKS_DIR="$REPO_DIR/tasks"

# 检查任务状态
check_task() {
    local task_id="$1"
    local task_file="$TASKS_DIR/$task_id.json"
    
    if [ ! -f "$task_file" ]; then
        return
    fi
    
    local status=$(node -e "console.log(require('$task_file').status)")
    local session_name="agent-$task_id"
    
    case "$status" in
        running)
            # 检查 tmux 会话是否还活着
            if tmux has-session -t "$session_name" 2>/dev/null; then
                # 检查是否有新提交
                local worktree=$(node -e "console.log(require('$task_file').worktree)")
                local branch=$(node -e "console.log(require('$task_file').branch)")
                
                cd "$REPO_DIR/$worktree"
                local commits=$(git log --oneline origin/main..HEAD 2>/dev/null | wc -l)
                
                if [ "$commits" -gt 0 ]; then
                    echo "📝 $task_id: $commits 个新提交"
                fi
            else
                # 会话结束，检查结果
                echo "⚠️ $task_id: Agent 会话已结束"
                check_pr "$task_id"
            fi
            ;;
        completed|failed)
            echo "✅ $task_id: 已完成 (状态: $status)"
            ;;
    esac
}

# 检查 PR 状态
check_pr() {
    local task_id="$1"
    local task_file="$TASKS_DIR/$task_id.json"
    
    # 这里可以添加检查 GitHub PR 状态的逻辑
    # 使用 gh pr status 或 GitHub API
}

# 监控所有任务
monitor_all() {
    echo "🔍 检查任务状态: $(date)"
    
    for task_file in "$TASKS_DIR"/*.json; do
        if [ -f "$task_file" ]; then
            local task_id=$(basename "$task_file" .json)
            check_task "$task_id"
        fi
    done
}

# 失败重试
retry_failed() {
    echo "🔄 检查需要重试的任务..."
    
    for task_file in "$TASKS_DIR"/*.json; do
        if [ -f "$task_file" ]; then
            local task_id=$(basename "$task_file" .json)
            local status=$(node -e "console.log(require('$task_file').status)")
            local retry_count=$(node -e "console.log(require('$task_file').retryCount || 0)")
            
            if [ "$status" = "failed" ] && [ "$retry_count" -lt 3 ]; then
                echo "🔁 重试任务: $task_id (第 $((retry_count + 1)) 次)"
                # 重试逻辑...
            fi
        fi
    done
}

# 主命令
case "${1:-}" in
    check)
        monitor_all
        ;;
    retry)
        retry_failed
        ;;
    *)
        monitor_all
        ;;
esac
