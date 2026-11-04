param(
  [string]$FlutterSdk = "$env:USERPROFILE/.cache/flutter-sdks/flutter-3.47.5",
  [string]$FirebaseAccount
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Push-Location $projectRoot
try {
  & "$PSScriptRoot/build_admin_site.ps1" -FlutterSdk $FlutterSdk
  if ($LASTEXITCODE -ne 0) { throw 'Admin build failed.' }
  $deployArgs = @('deploy', '--only', 'hosting', '--config', 'firebase.admin.json', '--project', 'yellow-ribbon-growing-prod', '--non-interactive')
  if ($FirebaseAccount) { $deployArgs += @('--account', $FirebaseAccount) }
  & firebase @deployArgs
  if ($LASTEXITCODE -ne 0) { throw 'Admin Firebase Hosting deployment failed.' }
} finally { Pop-Location }
