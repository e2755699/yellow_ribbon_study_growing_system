# UserPromptSubmit hook：攔截 /dashboard [active|ID]，直接輸出腳本結果並阻止送給模型。
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$inputJson = [Console]::In.ReadToEnd() | ConvertFrom-Json
$prompt = "$($inputJson.prompt)".Trim()
if ($prompt -notmatch '^/dashboard(?:\s+(\S+))?\s*$') { exit 0 }
$query = $Matches[1]
$script = Join-Path $PSScriptRoot 'show_task_dashboard.ps1'
try {
    $text = (& $script $query) -join "`n"
} catch {
    $text = "dashboard 失敗：$_"
}
# PS 5.1 的 ConvertTo-Json 會把部分換行輸出成字面 \n，改為手動跳脫
$escaped = $text.Replace('\', '\\').Replace('"', '\"').Replace("`r", '').Replace("`n", '\n').Replace("`t", '\t')
'{"decision":"block","reason":"' + $escaped + '"}'
