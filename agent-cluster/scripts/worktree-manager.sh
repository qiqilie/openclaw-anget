#!/bin/bash
# Git Worktree 管理脚本 - Vue3 + Node.js 版
# 用于创建隔离的分支环境

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
TASKS_DIR="$REPO_DIR/tasks"

# 用法说明
usage() {
    echo "用法: $0 <命令> <参数>"
    echo ""
    echo "命令:"
    echo "  create <任务名称> [分支名]  - 创建新任务"
    echo "  list                         - 列出所有任务"
    echo "  remove <任务名称>            - 移除任务"
    echo ""
    echo "示例:"
    echo "  $0 create feat-user-login"
    echo "  $0 create fix-login-bug bugfix/login"
    exit 1
}

# 安装依赖
install_deps() {
    local task_dir="$1"
    
    # 前端依赖
    if [ -f "$task_dir/frontend/package.json" ]; then
        echo "📥 安装前端依赖..."
        cd "$task_dir/frontend"
        pnpm install 2>/dev/null || npm install 2>/dev/null || yarn install 2>/dev/null || true
    fi
    
    # 后端依赖
    if [ -f "$task_dir/server/package.json" ]; then
        echo "📥 安装后端依赖..."
        cd "$task_dir/server"
        pnpm install 2>/dev/null || npm install 2>/dev/null || yarn install 2>/dev/null || true
    fi
}

# 创建新任务
create_task() {
    local task_name="$1"
    local branch_name="${2:-feature/$task_name}"
    
    echo "📦 创建任务: $task_name"
    echo "   分支: $branch_name"
    
    # 创建 worktree
    cd "$REPO_DIR"
    git worktree add "tasks/$task_name" -b "$branch_name"
    
    # 检查项目结构
    if [ -d "tasks/$task_name/frontend" ] || [ -d "tasks/$task_name/server" ]; then
        install_deps "tasks/$task_name"
    fi
    
    # 创建任务记录
    cat > "$TASKS_DIR/$task_name.json" << EOF
{
  "id": "$task_name",
  "branch": "$branch_name",
  "worktree": "tasks/$task_name",
  "status": "created",
  "createdAt": "$(date -u +%s)000",
  "agent": null,
  "description": "",
  "type": "feature",
  "stack": {
    "frontend": true,
    "backend": true
  }
}
EOF
    
    echo "✅ 任务创建完成: tasks/$task_name"
}

# 列出所有任务
list_tasks() {
    echo "📋 任务列表:"
    if [ ! -d "$TASKS_DIR" ] || [ -z "$(ls -A "$TASKS_DIR" 2>/dev/null)" ]; then
        echo "   (暂无任务)"
        return
    fi
    
    for task_file in "$TASKS_DIR"/*.json; do
        if [ -f "$task_file" ]; then
            local task_id=$(basename "$task_file" .json)
            local status=$(node -e "console.log(require('$task_file').status)" 2>/dev/null || echo "unknown")
            local agent=$(node -e "console.log(require('$task_file').agent || 'none')" 2>/dev/null || echo "none")
            echo "   - $task_id"
            echo "     状态: $status | Agent: $agent"
        fi
    done
}

# 移除任务
remove_task() {
    local task_name="$1"
    local task_dir="$REPO_DIR/tasks/$task_name"
    local task_file="$TASKS_DIR/$task_name.json"
    
    if [ ! -d "$task_dir" ]; then
        echo "❌ 任务不存在: $task_name"
        exit 1
    fi
    
    # 移除 worktree
    cd "$REPO_DIR"
    git worktree remove "$task_dir" --force 2>/dev/null || true
    
    # 移除任务记录
    rm -f "$task_file"
    
    echo "✅ 任务已移除: $task_name"
}

# 主命令处理
case "${1:-}" in
    create)
        if [ -z "${2:-}" ]; then
            echo "❌ 请指定任务名称"
            usage
        fi
        create_task "$2" "$3"
        ;;
    list)
        list_tasks
        ;;
    remove)
        if [ -z "${2:-}" ]; then
            echo "❌ 请指定任务名称"
            usage
        fi
        remove_task "$2"
        ;;
    *)
        usage
        ;;
esac
