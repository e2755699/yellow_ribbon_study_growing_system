param([string]$FlutterSdk = "$env:USERPROFILE/.cache/flutter-sdks/flutter-3.47.5")
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$flutterTool = Join-Path $FlutterSdk 'bin/flutter.bat'
$dartTool = Join-Path $FlutterSdk 'bin/dart.bat'
function Check-Exit { if ($LASTEXITCODE -ne 0) { throw "Design system check failed (exit $LASTEXITCODE)." } }
Push-Location $projectRoot
try {
  Push-Location widgetbook_gallery
  try {
    $generatedBefore = Get-Content -LiteralPath lib/main.directories.g.dart -Raw
    & $dartTool run build_runner build --delete-conflicting-outputs
    Check-Exit
    $generatedAfter = Get-Content -LiteralPath lib/main.directories.g.dart -Raw
    if ($generatedBefore -cne $generatedAfter) { throw 'Widgetbook catalog was stale. Review the generated update and rerun this check.' }
    & $flutterTool analyze --no-pub lib test
    Check-Exit
    & $flutterTool test --no-pub
    Check-Exit
  } finally { Pop-Location }
  & $flutterTool analyze --no-pub --no-fatal-infos lib/design_system lib/main/pages/student_info_page lib/main/pages/student_detail_page lib/main/components/student_info lib/main/components/avatar lib/main/components/yellow_ribbon lib/main/components/yb_layout.dart test/design_system_contract_test.dart
  Check-Exit
  & $flutterTool test --no-pub
  Check-Exit
  Write-Output 'Design system contract, Widgetbook previews and application tests passed.'
} finally { Pop-Location }
