param(
  [ValidateSet('Allowed', 'Denied')][string]$ExpectedAccess = 'Allowed'
)
$ErrorActionPreference = 'Stop'
$worker = 'https://yellow-ribbon-drive-poc.jackalopestudio0903.workers.dev'
$studentId = '980f2ad7-8553-461b-9a1c-23125bbfd406'
# Same public web API key as the App's prod FirebaseOptions; this is not a secret.
$firebaseApiKey = 'AIzaSyDuDSW13i5jJuEJetKvBsMGErj0jTI3lj4'
$repo = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$reportDir = Join-Path $repo '.release-private/drive-poc'
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$reportPath = Join-Path $reportDir ('live-' + $ExpectedAccess.ToLowerInvariant() + '-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff') + '.json')

function Get-Sha256([byte[]]$Bytes) {
  $hash = [System.Security.Cryptography.SHA256]::Create()
  try { return [System.BitConverter]::ToString($hash.ComputeHash($Bytes)).Replace('-', '').ToLowerInvariant() }
  finally { $hash.Dispose() }
}
function New-TestPdf {
  $ascii = [System.Text.Encoding]::ASCII
  $content = "BT /F1 12 Tf 30 100 Td (Yellow Ribbon synthetic Drive PoC) Tj ET`n"
  $objects = @(
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 300 150] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    ("<< /Length " + $ascii.GetByteCount($content) + " >>`nstream`n" + $content + 'endstream')
  )
  $text = "%PDF-1.4`n"
  $offsets = @()
  for ($i = 0; $i -lt $objects.Length; $i++) {
    $offsets += $ascii.GetByteCount($text)
    $text += ($i + 1).ToString() + " 0 obj`n" + $objects[$i] + "`nendobj`n"
  }
  $xref = $ascii.GetByteCount($text)
  $text += "xref`n0 6`n0000000000 65535 f `n"
  foreach ($offset in $offsets) { $text += $offset.ToString('D10') + " 00000 n `n" }
  $text += "trailer`n<< /Size 6 /Root 1 0 R >>`nstartxref`n$xref`n%%EOF`n"
  return ,$ascii.GetBytes($text)
}

Add-Type -AssemblyName System.Net.Http
$client = [System.Net.Http.HttpClient]::new()
$client.Timeout = [TimeSpan]::FromSeconds(120)
$report = [ordered]@{ studentId = $studentId; expectedAccess = $ExpectedAccess; status = 'not_started'; phase = 'login'; files = @(); checkedAtUtc = [DateTime]::UtcNow.ToString('o') }
$login = $null; $credentials = $null; $authBody = $null
try {
  Write-Host 'Use an EXISTING App email/password account. This does not create an account.'
  Write-Host ('Target: yellow-ribbon-growing-prod; test student only; expected access: ' + $ExpectedAccess)
  Write-Host 'Password and tokens stay in this process and are never written to the report.'
  $credentials = Get-Credential -Message 'Yellow Ribbon App login for Drive PoC (not your Google CLI login)'
  if (-not $credentials) { throw 'Login cancelled' }
  $authBody = @{ email = $credentials.UserName; password = $credentials.GetNetworkCredential().Password; returnSecureToken = $true } | ConvertTo-Json -Compress
  try {
    $login = Invoke-RestMethod -Uri "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$firebaseApiKey" -Method Post -ContentType 'application/json' -Body $authBody
  } catch { throw 'App login failed. Check the account in the App; no password or response is logged.' }
  $authBody = $null; $credentials = $null
  $client.DefaultRequestHeaders.Authorization = [System.Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $login.idToken)
  $login = $null

  # A harmless recovery query first checks the real teacher-to-student permission path.
  $report.phase = 'authorization_probe'
  $probeId = [guid]::NewGuid().ToString()
  # Retry only this read-only probe on service outages, keeping the token in memory.
  # Never retry an upload automatically: its previous outcome may be unknown.
  $probeDeadline = [DateTime]::UtcNow.AddMinutes(15)
  do {
    $probe = $client.GetAsync("$worker/v1/students/$studentId/uploads/$probeId").GetAwaiter().GetResult()
    try {
      $probeStatus = [int]$probe.StatusCode
      $report.authorizationStatus = $probeStatus
      $report.probeError = 'unrecognized_response'
      try {
        $probeBody = $probe.Content.ReadAsStringAsync().GetAwaiter().GetResult() | ConvertFrom-Json
        $knownErrors = @('poc_not_configured', 'outside_test_scope', 'identity_service_unavailable', 'invalid_login', 'student_access_denied', 'student_not_found', 'authorization_unavailable', 'drive_identity_unavailable', 'drive_unavailable', 'upstream_unavailable')
        if ($probeBody.error -cin $knownErrors) { $report.probeError = $probeBody.error }
        if ($probeStatus -eq 200) { $report.probeError = $null }
      } catch { }
    } finally { $probe.Dispose() }
    $report.status = 'checking'
    $report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $reportPath -Encoding UTF8
    if ($probeStatus -ne 503 -or [DateTime]::UtcNow -ge $probeDeadline) { break }
    Write-Host ('Service probe: ' + $report.probeError + '. Retrying read-only probe in 20 seconds; no upload yet. Ctrl+C stops.')
    Start-Sleep -Seconds 20
  } while ($true)
  if ($ExpectedAccess -eq 'Denied') {
    if ($probeStatus -ne 403) { throw ('Expected 403, received ' + $probeStatus) }
    $report.status = 'passed'; $report.authorizationStatus = $probeStatus
  } else {
    if ($probeStatus -ne 200) { throw ('Authorization/Drive probe returned HTTP ' + $probeStatus + '; no upload attempted.') }
    $fixtures = @(
      @{ name = 'poc-pixel.png'; mime = 'image/png'; bytes = [Convert]::FromBase64String('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=') },
      @{ name = 'poc-document.pdf'; mime = 'application/pdf'; bytes = (New-TestPdf) }
    )
    foreach ($fixture in $fixtures) {
      $report.phase = 'upload'
      $operationId = [guid]::NewGuid().ToString()
      $entry = [ordered]@{ operationId = $operationId; name = $fixture.name; status = 'pending'; expectedSha256 = Get-Sha256 $fixture.bytes }
      $report.files += $entry
      # Persist operation ID before the request; on uncertain outcome do not retry this script blindly.
      $report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $reportPath -Encoding UTF8
      $request = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Post, "$worker/v1/students/$studentId/files")
      $request.Content = [System.Net.Http.ByteArrayContent]::new([byte[]]$fixture.bytes)
      $request.Content.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::new($fixture.mime)
      $request.Headers.Add('X-File-Name', [Uri]::EscapeDataString($fixture.name))
      $request.Headers.Add('X-Upload-Id', $operationId)
      $entry.status = 'upload_outcome_unknown'
      try { $uploaded = $client.SendAsync($request).GetAwaiter().GetResult() }
      finally { $request.Dispose() }
      try {
        if ([int]$uploaded.StatusCode -ne 201) { throw ('Upload returned HTTP ' + [int]$uploaded.StatusCode + '; check saved operation ID before any retry.') }
        $ref = $uploaded.Content.ReadAsStringAsync().GetAwaiter().GetResult() | ConvertFrom-Json
        $entry.fileId = $ref.fileId
        $entry.status = 'uploaded'
      } finally { $uploaded.Dispose() }
      $report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $reportPath -Encoding UTF8
      $report.phase = 'download'
      $downloaded = $client.GetAsync("$worker/v1/students/$studentId/files/$($entry.fileId)").GetAwaiter().GetResult()
      try {
        if ([int]$downloaded.StatusCode -ne 200) { throw ('Download returned HTTP ' + [int]$downloaded.StatusCode) }
        $bytes = $downloaded.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
        $entry.actualSha256 = Get-Sha256 $bytes
        if ($entry.actualSha256 -ne $entry.expectedSha256) { throw 'Download SHA-256 mismatch' }
        $entry.status = 'passed'
      } finally { $downloaded.Dispose() }
    }
    $report.status = 'passed'
  }
  $report.phase = 'complete'
} catch {
  $report.status = 'needs_attention'
  # Only our own fixed errors are reported; never print raw HTTP request/credential objects.
  Write-Host 'Verification did not complete. Existing data is unchanged; see operation IDs in the local report.'
  if ($_.Exception.Message -match '^(App login failed|Expected 403|Authorization/Drive probe|Upload returned HTTP|Download returned HTTP|Download SHA-256 mismatch|Login cancelled)') {
    $report.reason = $_.Exception.Message
    Write-Host $report.reason
  }
} finally {
  $client.Dispose(); $login = $null; $authBody = $null; $credentials = $null
  $report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $reportPath -Encoding UTF8
  Write-Host ('Result: ' + $report.status)
  Write-Host ('Report: ' + $reportPath)
}
