# 任务监控脚本 - PowerShell 版
# 检查所有 Agent 状态

param(
    [Parameter(Position=0)]
    [string]$Command = "check"
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoDir = Split-Path -Parent $ScriptDir
$TasksDir = Join-Path $RepoDir "tasks"

# 检查任务状态
function Check-Task {
    param([string]$TaskId)
    
    $TaskFile = Join-Path $TasksDir "$TaskId.json"
    
    if (-not (Test-Path $TaskFile)) {
        return
    }
    
    try {
        $task = Get-Content $TaskFile | ConvertFrom-Json
    } catch {
        return
    }
    
    $status = $task.status
    $jobName = "agent-$TaskId"
    
    switch ($status) {
        "running" {
            # 检查后台作业是否还在运行
            $job = Get-Job -Name $jobName -ErrorAction SilentlyContinue
            
            if ($job -and $job.State -eq "Running") {
                # 检查是否有新提交
                $worktree = $task.worktree
                $branch = $task.branch
                
                $worktreePath = Join-Path $RepoDir $worktree
                if (Test-Path $worktreePath) {
                    Push-Location $worktreePath
                    try {
                        $commits = git log --oneline "origin/main..HEAD" 2>$null
                        if ($commits) {
                            $commitCount = ($commits | Measure-Object -Line).Lines
                            Write-Host "📝 $TaskId: $commitCount 个新提交" -ForegroundColor Cyan
                        }
                    } catch {}
                    Pop-Location
                }
            } else {
                # 作业结束，检查结果
                Write-Host "⚠️ $TaskId: Agent 作业已结束" -ForegroundColor Yellow
                Check-PR $TaskId
            }
        }
        "completed" {
            Write-Host "✅ $TaskId: 已完成" -ForegroundColor Green
        }
        "failed" {
            Write-Host "❌ $TaskId: 失败" -ForegroundColor Red
            if ($task.errorMessage) {
                Write-Host "   错误: $($task.errorMessage)" -ForegroundColor Red
            }
        }
    }
}

# 检查 PR 状态
function Check-PR {
    param([string]$TaskId)
    
    # 这里可以添加检查 GitHub PR 状态的逻辑
    # 需要先配置 GitHub CLI (gh)
    
    $TaskFile = Join-Path $TasksDir "$TaskId.json"
    if (Test-Path $TaskFile) {
        $task = Get-Content $TaskFile | ConvertFrom-Json
        
        # 检查是否有 PR URL
        if ($task.prUrl) {
            Write-Host "   PR: $($task.prUrl)" -ForegroundColor Gray
        }
    }
}

# 监控所有任务
function Monitor-All {
    Write-Host "🔍 检查任务状态: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-Path $TasksDir)) {
        Write-Host "📋 暂无任务"
        return
    }
    
    $taskFiles = Get-ChildItem -Path $TasksDir -Filter "*.json" -ErrorAction SilentlyContinue
    
    if ($taskFiles.Count -eq 0) {
        Write-Host "📋 暂无任务"
        return
    }
    
    Write-Host "运行中的任务:" -ForegroundColor Yellow
    
    $hasRunning = $false
    
    foreach ($file in $taskFiles) {
        $taskId = $file.BaseName
        $task = try { Get-Content $file.FullName | ConvertFrom-Json } catch { continue }
        
        if ($task.status -eq "running") {
            $hasRunning = $true
            $jobName = "agent-$taskId"
            $job = Get-Job -Name $jobName -ErrorAction SilentlyContinue
            
            $jobStatus = if ($job -and $job.State -eq "Running") { "🟢 运行中" } else { "⚪ 已停止" }
            
            Write-Host "   $jobStatus $($taskId)" -ForegroundColor White
            Write-Host "        Agent: $($task.agent) ($($task.model))"
            
            # 获取最新输出
            if ($job) {
                $output = Receive-Job -Job $job -ErrorAction SilentlyContinue
                if ($output) {
                    $lastLines = $output[-3..-1]
                    foreach ($line in $lastLines) {
                        if ($line) { Write-Host "        > $($line.Substring(0, [Math]::Min(60, $line.Length)))" -ForegroundColor Gray }
                    }
                }
            }
        }
    }
    
    if (-not $hasRunning) {
        Write-Host "   (暂无运行中的任务)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "其他任务:" -ForegroundColor Yellow
    
    foreach ($file in $taskFiles) {
        $taskId = $file.BaseName
        $task = try { Get-Content $file.FullName | ConvertFrom-Json } catch { continue }
        
        if ($task.status -ne "running") {
            $statusIcon = switch ($task.status) {
                "completed" { "✅" }
                "failed" { "❌" }
                "created" { "📦" }
                default { "📋" }
            }
            
            Write-Host "   $statusIcon $($taskId): $($task.status)" -ForegroundColor White
        }
    }
}

# 失败重试
function Retry-Failed {
    Write-Host "🔄 检查需要重试的任务..." -ForegroundColor Cyan
    
    if (-not (Test-Path $TasksDir)) {
        return
    }
    
    $taskFiles = Get-ChildItem -Path $TasksDir -Filter "*.json" -ErrorAction SilentlyContinue
    
    foreach ($file in $taskFiles) {
        $task = try { Get-Content $file.FullName | ConvertFrom-Json } catch { continue }
        
        if ($task.status -eq "failed") {
            $retryCount = if ($task.retryCount) { $task.retryCount } else { 0 }
            
            if ($retryCount -lt 3) {
                Write-Host "🔁 重试任务: $($task.id) (第 $($retryCount + 1) 次)" -ForegroundColor Yellow
                
                # 重试逻辑 - 可以调用 agent-launcher 重新启动
                # 这里只是更新状态
                $task.retryCount = $retryCount + 1
                $task.status = "created"
                $task | ConvertTo-Json -Depth 3 | Out-File -FilePath $file.FullName -Encoding UTF8
            }
        }
    }
}

# 清理已完成的任务
function Clean-Tasks {
    Write-Host "🧹 清理已完成的任务..." -ForegroundColor Cyan
    
    if (-not (Test-Path $TasksDir)) {
        return
    }
    
    $taskFiles = Get-ChildItem -Path $TasksDir -Filter "*.json" -ErrorAction SilentlyContinue
    
    foreach ($file in $taskFiles) {
        $task = try { Get-Content $file.FullName | ConvertFrom-Json } catch { continue }
        
        if ($task.status -eq "completed") {
            $age = [DateTimeOffset]::Now.ToUnixTimeMilliseconds() - $task.completedAt
            $daysOld = $age / (1000 * 60 * 60 * 24)
            
            if ($daysOld -gt 7) {
                Write-Host "   🗑️  删除旧任务: $($task.id) (完成于 $($daysOld) 天前)" -ForegroundColor Gray
                # 可以在这里删除 worktree
            }
        }
    }
}

# 用法说明
function Show-Usage {
    Write-Host "用法: .\monitor.ps1 <命令>" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "命令:" -ForegroundColor Yellow
    Write-Host "  check   - 检查所有任务状态 (默认)"
    Write-Host "  retry   - 重试失败的任务"
    Write-Host "  clean   - 清理旧任务"
    Write-Host ""
    Write-Host "示例:" -ForegroundColor Yellow
    Write-Host "  .\monitor.ps1"
    Write-Host "  .\monitor.ps1 check"
}

# 主命令处理
switch ($Command.ToLower()) {
    "check" { Monitor-All }
    "retry" { Retry-Failed }
    "clean" { Clean-Tasks }
    default { Show-Usage }
}

Write-Host ""
Write-Host "提示: 可以用以下命令设置定时监控:" -ForegroundColor Gray
Write-Host "  while($true) { .\monitor.ps1; Start-Sleep -Seconds 600 }" -ForegroundColor Gray
