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
  # Firebase can cache an unversioned main.dart.js for an hour. Give every
  # compiled entry point a content hash so a normal refresh loads this release.
  $entryPath = Join-Path $OutputDirectory 'main.dart.js'
  $entryHash = (Get-FileHash -LiteralPath $entryPath -Algorithm SHA256).Hash.Substring(0, 16).ToLowerInvariant()
  $versionedEntry = "main.$entryHash.dart.js"
  Copy-Item -LiteralPath $entryPath -Destination (Join-Path $OutputDirectory $versionedEntry)
  # This project's index embeds flutter_bootstrap_js inline as well.
  $index = $index.Replace('"mainJsPath":"main.dart.js"', '"mainJsPath":"' + $versionedEntry + '"')
  [IO.File]::WriteAllText((Join-Path $projectRoot $indexPath), $index, [Text.UTF8Encoding]::new($false))
  $bootstrapPath = Join-Path $OutputDirectory 'flutter_bootstrap.js'
  $bootstrap = [IO.File]::ReadAllText((Join-Path $projectRoot $bootstrapPath))
  $bootstrap = $bootstrap.Replace('"mainJsPath":"main.dart.js"', '"mainJsPath":"' + $versionedEntry + '"')
  if (!$bootstrap.Contains('"mainJsPath":"' + $versionedEntry + '"')) { throw 'Versioned admin entry was not configured.' }
  [IO.File]::WriteAllText((Join-Path $projectRoot $bootstrapPath), $bootstrap, [Text.UTF8Encoding]::new($false))
  # The standalone admin is an online report viewer, not an offline student cache.
  [IO.File]::WriteAllText((Join-Path $projectRoot (Join-Path $OutputDirectory 'manifest.json')), '{"name":"黃絲帶管理後台","short_name":"黃絲帶後台","start_url":"/","display":"browser","description":"月出席報表與 PDF 下載"}', [Text.UTF8Encoding]::new($false))
  Write-Output "Admin site is ready in $OutputDirectory (no production records bundled)."
} finally { Pop-Location }
