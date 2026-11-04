param(
  [string]$FlutterSdk = "$env:USERPROFILE/.cache/flutter-sdks/flutter-3.47.5",
  [string]$OutputDirectory = 'build/admin-web'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Push-Location $projectRoot
try {
  & "$FlutterSdk/bin/flutter.bat" build web --release --target lib/admin_main.dart --output $OutputDirectory --no-tree-shake-icons --no-wasm-dry-run
  if ($LASTEXITCODE -ne 0) { throw 'Admin Web build failed.' }
  $indexPath = Join-Path $OutputDirectory 'index.html'
  $index = [IO.File]::ReadAllText((Join-Path $projectRoot $indexPath))
  $index = $index -replace '<title>.*?</title>', '<title>黃絲帶管理後台 · 月出席報表</title>'
  $index = $index -replace '<meta[^>]+(?:property="og:|name="twitter:)[^>]+>', ''
  $index = $index -replace 'content="YellowRibbonStudyGrowingSystem"', 'content="黃絲帶管理後台"'
  $index = $index -replace 'content="Built with FlutterFlow\."', 'content="瀏覽每月出席報表，下載橫式 PDF。"'
  $index = $index -replace '<html>', '<html lang="zh-Hant">'
  [IO.File]::WriteAllText((Join-Path $projectRoot $indexPath), $index, [Text.UTF8Encoding]::new($false))
  # The standalone admin is an online report viewer, not an offline student cache.
  [IO.File]::WriteAllText((Join-Path $projectRoot (Join-Path $OutputDirectory 'manifest.json')), '{"name":"黃絲帶管理後台","short_name":"黃絲帶後台","start_url":"/","display":"browser","description":"月出席報表與 PDF 下載"}', [Text.UTF8Encoding]::new($false))
  Write-Output "Admin site is ready in $OutputDirectory (no production records bundled)."
} finally { Pop-Location }
