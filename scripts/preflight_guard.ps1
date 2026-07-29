param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectRoot
)

if (-not [System.IO.Path]::IsPathRooted($ProjectRoot)) {
  throw 'ProjectRoot must be an absolute path.'
}

$resolvedRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
$workFolderName = -join @(
  [char]0x5236
  [char]0x4F5C
  [char]0x8FC7
  [char]0x7A0B
)
$statePath = Join-Path $resolvedRoot "$workFolderName\planning\project-state.json"
if (-not (Test-Path -LiteralPath $statePath)) {
  throw "Project state not found: $statePath"
}

$state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
$missing = [System.Collections.Generic.List[string]]::new()
$preflight = $state.preflight

if ($null -eq $preflight) {
  $missing.Add('preflight section')
} else {
  if ($preflight.status -ne 'approved') {
    $missing.Add('preflight.status=approved')
  }
  if ($preflight.narrationReceived -ne $true) {
    $missing.Add('narrationReceived=true')
  }
  if ($preflight.outputPathConfirmed -ne $true) {
    $missing.Add('outputPathConfirmed=true')
  }
  if ([string]::IsNullOrWhiteSpace([string]$preflight.voiceProvider)) {
    $missing.Add('voiceProvider')
  }
  if ([string]::IsNullOrWhiteSpace([string]$preflight.voiceId)) {
    $missing.Add('voiceId')
  }
  if ([string]::IsNullOrWhiteSpace([string]$preflight.voiceModel)) {
    $missing.Add('voiceModel')
  }
  if ($null -eq $preflight.apiCredentialRequired) {
    $missing.Add('apiCredentialRequired=true|false')
  } elseif ($preflight.apiCredentialRequired -eq $true -and $preflight.apiCredentialAvailable -ne $true) {
    $missing.Add('apiCredentialAvailable=true')
  }
  if ($null -eq $preflight.targetLufs) {
    $missing.Add('targetLufs')
  }
  if ([string]::IsNullOrWhiteSpace([string]$preflight.aspectRatio)) {
    $missing.Add('aspectRatio')
  }
  if ([string]::IsNullOrWhiteSpace([string]$preflight.resolution)) {
    $missing.Add('resolution')
  }
  if ($null -eq $preflight.fps) {
    $missing.Add('fps')
  }
  if ([string]::IsNullOrWhiteSpace([string]$preflight.styleReference)) {
    $missing.Add('styleReference')
  }
}

if ($missing.Count -gt 0) {
  $missing | ForEach-Object { Write-Output "MISSING: $_" }
  Write-Error 'Preflight guard failed. Ask the user for the blocking non-secret settings before production.'
  exit 1
}

Write-Output (
  'Preflight passed: provider={0}, voice={1}, model={2}, loudness={3} LUFS, canvas={4} {5} @ {6}fps.' -f
  $preflight.voiceProvider,
  $preflight.voiceId,
  $preflight.voiceModel,
  $preflight.targetLufs,
  $preflight.aspectRatio,
  $preflight.resolution,
  $preflight.fps
)
