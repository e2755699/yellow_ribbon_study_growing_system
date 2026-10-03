param(
    [string]$TaskId,
    [switch]$Active
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
# /dashboard active 以位置參數傳入
if ($TaskId -eq 'active') { $Active = $true; $TaskId = '' }
$dashboardRegistry = Join-Path (Split-Path $PSScriptRoot -Parent) 'docs/task-dashboard.md'
$dashboardTasks = @(Get-Content -LiteralPath $dashboardRegistry -Encoding utf8 | ForEach-Object {
    if ($_ -match '^\|\s*([A-Z]+-[A-Z0-9]+(?:\.\d+)*)\s*\|') {
        $cells = $_ -split '\|'
        if ($cells.Count -ne 10) { throw "Invalid task row: $($Matches[1])" }
        [pscustomobject]@{
            Id = $cells[1].Trim()
            Name = $cells[3].Trim()
            Status = $cells[4].Trim()
            Progress = $cells[5].Trim()
            Next = $cells[6].Trim()
            Checked = $cells[7].Trim()
        }
    }
})
if ($dashboardTasks.Count -eq 0) { throw 'No tasks registered.' }
if (@($dashboardTasks.Id | Select-Object -Unique).Count -ne $dashboardTasks.Count) {
    throw 'Duplicate task IDs found.'
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
    Write-Output "  進度：$(Clean $t.Progress)"
    Write-Output "  下一步：$(Clean $t.Next)"
    Write-Output "  核對：$($t.Checked)"
    return
}
$statusOrder = @('受阻', '進行中', '待驗收', '未開始', '已暫停', '已完成', '已取消')
$idWidth = ($dashboardTasks.Id | Measure-Object -Property Length -Maximum).Maximum
Write-Output "任務 $($dashboardTasks.Count) 項（本機索引快照，未即時核對）"
foreach ($status in $statusOrder) {
    $group = @($dashboardTasks | Where-Object Status -EQ $status)
    if ($group.Count -eq 0) { continue }
    Write-Output ''
    Write-Output "■ $status（$($group.Count)）"
    foreach ($t in $group) {
        Write-Output "  $($t.Id.PadRight($idWidth))  $($t.Name)"
        if ($status -notin @('已完成', '已取消')) {
            Write-Output "  $(' ' * $idWidth)  → $(Clean $t.Next)"
        }
    }
}
