# Agent 启动器脚本 - PowerShell 版
# 根据任务类型选择合适的 Agent (使用后台作业替代 tmux)

param(
    [Parameter(Position=0)]
    [string]$Command = "",
    
    [Parameter(Position=1)]
    [string]$TaskId = "",
    
    [Parameter(Position=2)]
    [string]$AgentType = "codex",
    
    [Parameter(Position=3)]
    [string]$Model = ""
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoDir = Split-Path -Parent $ScriptDir
$ConfigDir = Join-Path $RepoDir "config"
$TasksDir = Join-Path $RepoDir "tasks"

# 加载 Agent 配置
$AgentsConfig = Join-Path $ConfigDir "agents.json"

# 选择 Agent
function Select-Agent {
    param([string]$TaskType)
    
    $agent = "codex"
    
    switch -Regex ($TaskType.ToLower()) {
        "backend|api|bugfix|refactor|server|node" { $agent = "codex" }
        "frontend|vue|vite|component|ui|react" { $agent = "claude-code" }
        "design|style|css|animation" { $agent = "gemini" }
    }
    
    return $agent
}

# 启动 Agent
function Start-Agent {
    param(
        [string]$TaskId,
        [string]$AgentType,
        [string]$Model
    )
    
    $TaskDir = Join-Path $RepoDir "tasks\$TaskId"
    
    if (-not (Test-Path $TaskDir)) {
        Write-Host "❌ 任务目录不存在: $TaskDir" -ForegroundColor Red
        exit 1
    }
    
    # 读取任务配置
    $TaskFile = Join-Path $TasksDir "$TaskId.json"
    if (-not (Test-Path $TaskFile)) {
        Write-Host "❌ 任务配置文件不存在: $TaskFile" -ForegroundColor Red
        exit 1
    }
    
    $task = Get-Content $TaskFile | ConvertFrom-Json
    
    # 确定 Agent 类型
    if (-not $AgentType) {
        $AgentType = Select-Agent $task.type
    }
    
    # 确定模型
    if (-not $Model) {
        $Model = switch ($AgentType) {
            "codex" { "gpt-5.3-codex" }
            "claude-code" { "claude-opus-4.5" }
            "gemini" { "gemini-2.0" }
        }
    }
    
    Write-Host "🚀 启动 Agent: $AgentType ($Model)" -ForegroundColor Green
    Write-Host "   任务: $TaskId"
    Write-Host "   目录: $TaskDir"
    
    # 启动后台作业
    $jobName = "agent-$TaskId"
    
    # 根据 Agent 类型构建启动命令
    $startCommand = switch ($AgentType) {
        "codex" { "codex" }
        "claude-code" { "claude" }
        "gemini" { "gemini" }
        default { "codex" }
    }
    
    # 创建启动脚本
    $launchScript = Join-Path $env:TEMP "launch_agent_$TaskId.ps1"
    @"
# Agent 启动脚本
Set-Location "$TaskDir"
Write-Host "Agent 启动中: $AgentType"
$startCommand
"@ | Out-File -FilePath $launchScript -Encoding UTF8
    
    # 启动后台作业
    $job = Start-Job -Name $jobName -FilePath $launchScript
    
    # 更新任务状态
    $task.status = "running"
    $task.agent = $AgentType
    $task.model = $Model
    $task.startedAt = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
    $task | ConvertTo-Json -Depth 3 | Out-File -FilePath $TaskFile -Encoding UTF8
    
    Write-Host "✅ Agent 已启动: $jobName" -ForegroundColor Green
    Write-Host "   查看状态: Get-Job -Name $jobName"
    Write-Host "   查看输出: Receive-Job -Name $jobName"
    Write-Host "   停止: Stop-Job -Name $jobName"
}

# 发送消息给 Agent
function Send-ToAgent {
    param(
        [string]$TaskId,
        [string]$Message
    )
    
    $jobName = "agent-$TaskId"
    
    $job = Get-Job -Name $jobName -ErrorAction SilentlyContinue
    if (-not $job) {
        Write-Host "❌ Agent 作业不存在: $jobName" -ForegroundColor Red
        return
    }
    
    # 通过输入文件发送命令
    $inputFile = Join-Path $env:TEMP "agent_input_$TaskId.txt"
    $Message | Out-File -FilePath $inputFile -Encoding UTF8
    
    Write-Host "📤 已发送消息到 Agent $TaskId" -ForegroundColor Green
    Write-Host "   消息: $Message"
}

# 列出所有 Agent
function Get-AgentList {
    Write-Host "📋 运行中的 Agents:" -ForegroundColor Cyan
    
    $jobs = Get-Job | Where-Object { $_.Name -like "agent-*" }
    
    if ($jobs.Count -eq 0) {
        Write-Host "   (暂无运行中的 Agent)"
        return
    }
    
    foreach ($job in $jobs) {
        $taskId = $job.Name -replace "agent-", ""
        $status = if ($job.State -eq "Running") { "运行中" } else { $job.State }
        
        Write-Host "   - $($job.Name): $status" -ForegroundColor White
        
        # 尝试读取任务信息
        $TaskFile = Join-Path $TasksDir "$taskId.json"
        if (Test-Path $TaskFile) {
            try {
                $task = Get-Content $TaskFile | ConvertFrom-Json
                Write-Host "     任务: $($task.description ?? $task.id)"
                Write-Host "     Agent: $($task.agent) ($($task.model))"
            } catch {}
        }
    }
}

# 用法说明
function Show-Usage {
    Write-Host "用法: .\agent-launcher.ps1 <命令> <参数>" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "命令:" -ForegroundColor Yellow
    Write-Host "  launch <task_id> [agent_type] [model]  - 启动 Agent"
    Write-Host "  send <task_id> <message>              - 发送消息给 Agent"
    Write-Host "  list                                  - 列出运行中的 Agents"
    Write-Host ""
    Write-Host "Agent 类型:" -ForegroundColor Yellow
    Write-Host "  codex        - 后端/复杂逻辑"
    Write-Host "  claude-code  - 前端/Vue"
    Write-Host "  gemini       - UI 设计"
    Write-Host ""
    Write-Host "示例:" -ForegroundColor Yellow
    Write-Host "  .\agent-launcher.ps1 launch feat-login"
    Write-Host "  .\agent-launcher.ps1 launch feat-login codex"
    Write-Host "  .\agent-launcher.ps1 list"
}

# 主命令处理
switch ($Command.ToLower()) {
    "launch" { 
        if (-not $TaskId) {
            Write-Host "❌ 请指定任务 ID" -ForegroundColor Red
            Show-Usage
            exit 1
        }
        Start-Agent -TaskId $TaskId -AgentType $AgentType -Model $Model 
    }
    "send" { 
        if (-not $TaskId -or -not $AgentType) {
            Write-Host "❌ 请指定任务 ID 和消息" -ForegroundColor Red
            Show-Usage
            exit 1
        }
        Send-ToAgent -TaskId $TaskId -Message $AgentType 
    }
    "list" { Get-AgentList }
    "select" { 
        if ($TaskId) { Select-Agent $TaskId }
    }
    default { Show-Usage }
}
