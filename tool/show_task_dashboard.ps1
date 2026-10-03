param(
    [string]$TaskId,
    [switch]$Active,
    [switch]$Local
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
# /dashboard active 以位置參數傳入
if ($TaskId -eq 'active') { $Active = $true; $TaskId = '' }
# 唯一來源是 origin/master；-Local 只在離線或除錯時讀工作目錄
$repoRoot = Split-Path $PSScriptRoot -Parent
$registryPath = 'docs/task-dashboard.md'
if ($Local) {
    $lines = Get-Content -LiteralPath (Join-Path $repoRoot $registryPath) -Encoding utf8
    $sourceNote = '本機工作目錄'
} else {
    git -C $repoRoot fetch -q origin master 2>$null
    $sourceNote = if ($LASTEXITCODE -eq 0) { 'origin/master（已 fetch）' } else { 'origin/master（fetch 失敗，可能不是最新）' }
    $lines = (git -C $repoRoot -c core.quotepath=off show "origin/master:$registryPath") -split "`n"
}
$header = $lines | Where-Object { $_ -match '^\|\s*ID\s*\|' } | Select-Object -First 1
if (-not $header) { throw 'Task table header not found.' }
$columns = @($header -split '\|' | ForEach-Object { $_.Trim() })
function Col([string[]]$cells, [string]$name) {
    $i = [array]::IndexOf($columns, $name)
    if ($i -lt 0) { return '' }
    $cells[$i].Trim()
}
$dashboardTasks = @($lines | ForEach-Object {
    if ($_ -match '^\|\s*([A-Z]+-[A-Z0-9]+(?:\.\d+)*)\s*\|') {
        $cells = $_ -split '\|'
        if ($cells.Count -ne $columns.Count) { throw "Invalid task row: $($Matches[1])" }
        [pscustomobject]@{
            Id = Col $cells 'ID'
            Name = Col $cells '任務'
            Status = Col $cells '狀態'
            Owner = Col $cells '負責'
            Branch = Col $cells '分支'
            Progress = Col $cells '進度簡述'
            Next = Col $cells '下一步／阻擋'
            Checked = Col $cells '最後核對'
        }
    }
})
if ($dashboardTasks.Count -eq 0) { throw 'No tasks registered.' }
if (@($dashboardTasks.Id | Select-Object -Unique).Count -ne $dashboardTasks.Count) {
    throw 'Duplicate task IDs found.'
}
# 已併入其他任務的舊 ID：索引內「- `舊ID` → `新ID`」的對照行
$aliasLine = '^- `([A-Z]+-[A-Z0-9]+(?:\.\d+)*)` → `([A-Z]+-[A-Z0-9]+(?:\.\d+)*)`'
$aliases = @{}
$lines | ForEach-Object { if ($_ -match $aliasLine) { $aliases[$Matches[1]] = $Matches[2] } }
if ($TaskId -and $aliases.ContainsKey($TaskId) -and -not ($dashboardTasks.Id -contains $TaskId)) {
    Write-Output "$TaskId 已併入 $($aliases[$TaskId])"
    $TaskId = $aliases[$TaskId]
}
if ($TaskId) {
    $dashboardTasks = @($dashboardTasks | Where-Object Id -EQ $TaskId)
    if ($dashboardTasks.Count -eq 0) { throw "Unknown task ID: $TaskId" }
}
if ($Active) {
    $dashboardTasks = @($dashboardTasks | Where-Object Status -NotIn @('已完成', '已取消'))
}
function Clean([string]$s) { $s -replace '`', '' }
if ($TaskId) {
    $t = $dashboardTasks[0]
    Write-Output "$($t.Id)  $($t.Name)  [$($t.Status)]"
    if ($t.Owner -or $t.Branch) { Write-Output "  負責：$($t.Owner)　分支：$(Clean $t.Branch)" }
    Write-Output "  進度：$(Clean $t.Progress)"
    Write-Output "  下一步：$(Clean $t.Next)"
    Write-Output "  核對：$($t.Checked)"
    return
}
$statusOrder = @('受阻', '進行中', '待驗收', '未開始', '已暫停', '已完成', '已取消')
$idWidth = ($dashboardTasks.Id | Measure-Object -Property Length -Maximum).Maximum
Write-Output "任務 $($dashboardTasks.Count) 項（來源：$sourceNote）"
foreach ($status in $statusOrder) {
    $group = @($dashboardTasks | Where-Object Status -EQ $status)
    if ($group.Count -eq 0) { continue }
    Write-Output ''
    Write-Output "■ $status（$($group.Count)）"
    foreach ($t in $group) {
        $who = @($t.Owner, (Clean $t.Branch)) | Where-Object { $_ }
        $suffix = if ($who) { "  ［$($who -join ' · ')］" } else { '' }
        Write-Output "  $($t.Id.PadRight($idWidth))  $($t.Name)$suffix"
        if ($status -notin @('已完成', '已取消')) {
            Write-Output "  $(' ' * $idWidth)  → $(Clean $t.Next)"
        }
    }
}
