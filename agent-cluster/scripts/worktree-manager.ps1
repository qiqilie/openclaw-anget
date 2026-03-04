# Git Worktree 管理脚本 - PowerShell 版
# 用于创建隔离的分支环境

param(
    [Parameter(Position=0)]
    [string]$Command = "",
    
    [Parameter(Position=1)]
    [string]$TaskName = "",
    
    [Parameter(Position=2)]
    [string]$BranchName = ""
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoDir = Split-Path -Parent $ScriptDir
$TasksDir = Join-Path $RepoDir "tasks"

# 用法说明
function Show-Usage {
    Write-Host "用法: .\worktree-manager.ps1 <命令> <参数>" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "命令:" -ForegroundColor Yellow
    Write-Host "  create <任务名称> [分支名]  - 创建新任务"
    Write-Host "  list                         - 列出所有任务"
    Write-Host "  remove <任务名称>            - 移除任务"
    Write-Host ""
    Write-Host "示例:" -ForegroundColor Yellow
    Write-Host "  .\worktree-manager.ps1 create feat-user-login"
    Write-Host "  .\worktree-manager.ps1 create fix-login-bug bugfix/login"
}

# 安装依赖
function Install-Deps {
    param([string]$TaskDir)
    
    # 前端依赖
    $FrontendPackage = Join-Path $TaskDir "frontend\package.json"
    if (Test-Path $FrontendPackage) {
        Write-Host "📥 安装前端依赖..." -ForegroundColor Green
        Push-Location (Join-Path $TaskDir "frontend")
        try {
            if (Get-Command pnpm -ErrorAction SilentlyContinue) { pnpm install }
            elseif (Get-Command npm -ErrorAction SilentlyContinue) { npm install }
        } finally { Pop-Location }
    }
    
    # 后端依赖
    $BackendPackage = Join-Path $TaskDir "server\package.json"
    if (Test-Path $BackendPackage) {
        Write-Host "📥 安装后端依赖..." -ForegroundColor Green
        Push-Location (Join-Path $TaskDir "server")
        try {
            if (Get-Command pnpm -ErrorAction SilentlyContinue) { pnpm install }
            elseif (Get-Command npm -ErrorAction SilentlyContinue) { npm install }
        } finally { Pop-Location }
    }
}

# 创建新任务
function New-Task {
    if (-not $TaskName) {
        Write-Host "❌ 请指定任务名称" -ForegroundColor Red
        Show-Usage
        return
    }
    
    if (-not $BranchName) {
        $BranchName = "feature/$TaskName"
    }
    
    Write-Host "📦 创建任务: $TaskName" -ForegroundColor Green
    Write-Host "   分支: $BranchName"
    
    $TaskDir = Join-Path $TasksDir $TaskName
    
    # 创建 worktree
    Set-Location $RepoDir
    $result = git worktree add $TaskDir -b $BranchName 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  worktree 可能已存在或出错: $result" -ForegroundColor Yellow
    }
    
    # 检查项目结构并安装依赖
    if ((Test-Path (Join-Path $TaskDir "frontend")) -or (Test-Path (Join-Path $TaskDir "server"))) {
        Install-Deps $TaskDir
    }
    
    # 创建任务记录 JSON
    $TaskJson = @{
        id = $TaskName
        branch = $BranchName
        worktree = "tasks\$TaskName"
        status = "created"
        createdAt = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
        agent = $null
        description = ""
        type = "feature"
        stack = @{
            frontend = $true
            backend = $true
        }
    } | ConvertTo-Json -Depth 3
    
    $TaskFile = Join-Path $TasksDir "$TaskName.json"
    $TaskJson | Out-File -FilePath $TaskFile -Encoding UTF8
    
    Write-Host "✅ 任务创建完成: tasks\$TaskName" -ForegroundColor Green
}

# 列出所有任务
function Get-TaskList {
    Write-Host "📋 任务列表:" -ForegroundColor Cyan
    
    if (-not (Test-Path $TasksDir)) {
        Write-Host "   (暂无任务目录)"
        return
    }
    
    $taskFiles = Get-ChildItem -Path $TasksDir -Filter "*.json" -ErrorAction SilentlyContinue
    if ($taskFiles.Count -eq 0) {
        Write-Host "   (暂无任务)"
        return
    }
    
    foreach ($file in $taskFiles) {
        try {
            $task = Get-Content $file.FullName | ConvertFrom-Json
            Write-Host "   - $($task.id)" -ForegroundColor White
            Write-Host "     状态: $($task.status) | Agent: $($task.agent ?? 'none')"
        } catch {
            Write-Host "   - $($file.BaseName) (解析失败)"
        }
    }
}

# 移除任务
function Remove-Task {
    if (-not $TaskName) {
        Write-Host "❌ 请指定任务名称" -ForegroundColor Red
        Show-Usage
        return
    }
    
    $TaskDir = Join-Path $TasksDir $TaskName
    $TaskFile = Join-Path $Name.json"
    
    if (-not (Test-Path $TaskDir)) {
        Write-HostTasksDir "$Task "❌ 任务目录不存在: $TaskDir" -ForegroundColor Red
        return
    }
    
    Set-Location $RepoDir
    git worktree remove $TaskDir --force 2>$null
    
    if (Test-Path $TaskFile) {
        Remove-Item $TaskFile -Force
    }
    
    Write-Host "✅ 任务已移除: $TaskName" -ForegroundColor Green
}

# 主命令处理
switch ($Command.ToLower()) {
    "create" { New-Task }
    "list" { Get-TaskList }
    "remove" { Remove-Task }
    default { Show-Usage }
}
