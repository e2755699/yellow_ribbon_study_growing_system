param([string]$FlutterSdk = "$env:USERPROFILE/.cache/flutter-sdks/flutter-3.47.5", [string]$NodeModulesPath)
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$flutterTool = Join-Path $FlutterSdk 'bin/flutter.bat'
if (!(Test-Path -LiteralPath $flutterTool)) { throw "Flutter not found: $flutterTool" }
foreach ($port in @(8194,4494,4594,9194)) {
  if (Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue) { throw "Emulator port $port is occupied; stop its owner before running." }
}
$previousExport=$env:ROSTER_EXPORT_TRACE
$previousPort=$env:ROSTER_RULES_PORT
$previousNodePath=$env:NODE_PATH
Push-Location $repoRoot
try {
  $env:ROSTER_EXPORT_TRACE='1'
  & $flutterTool test test/domain/roster/roster_commands_test.dart --plain-name 'export production planner traces'
  if ($LASTEXITCODE -ne 0) { throw 'Dart planner trace generation failed.' }
  if ($NodeModulesPath) { $env:NODE_PATH=[IO.Path]::GetFullPath($NodeModulesPath) }
  elseif (!(Test-Path -LiteralPath 'firebase/tests/node_modules')) {
    & npm.cmd ci --ignore-scripts --prefix firebase/tests
    if ($LASTEXITCODE -ne 0) { throw 'Rules test dependency installation failed.' }
  }
  $env:ROSTER_RULES_PORT='8194'
  Set-Location firebase/tests
  & firebase.cmd emulators:exec --config ../roster-client-emulator.json --project demo-yellow-ribbon-roster --only firestore 'node --test --test-concurrency=1 roster.rules.test.cjs roster.client.rules.test.cjs roster.planner.rules.test.cjs roster.profile.rules.test.cjs'
  if ($LASTEXITCODE -ne 0) { throw 'Client Rules tests failed.' }
} finally {
  Pop-Location
  $env:ROSTER_EXPORT_TRACE=$previousExport
  $env:ROSTER_RULES_PORT=$previousPort
  $env:NODE_PATH=$previousNodePath
}
