param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectRoot,
  [string]$ScriptPath
)

if (-not [System.IO.Path]::IsPathRooted($ProjectRoot)) {
  throw 'ProjectRoot must be an absolute path.'
}

$resolvedRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
$workRoot = Join-Path $resolvedRoot '制作过程'
$directories = @(
  $resolvedRoot,
  $workRoot,
  (Join-Path $workRoot 'assets\characters'),
  (Join-Path $workRoot 'assets\generated'),
  (Join-Path $workRoot 'assets\props'),
  (Join-Path $workRoot 'assets\fonts'),
  (Join-Path $workRoot 'audio'),
  (Join-Path $workRoot 'captions'),
  (Join-Path $workRoot 'compositions\scenes'),
  (Join-Path $workRoot 'planning'),
  (Join-Path $workRoot 'snapshots'),
  (Join-Path $workRoot 'renders'),
  (Join-Path $workRoot 'logs')
)

foreach ($directory in $directories) {
  New-Item -ItemType Directory -Path $directory -Force | Out-Null
}

if ($ScriptPath) {
  $resolvedScript = (Resolve-Path -LiteralPath $ScriptPath).Path
  $targetScript = Join-Path $resolvedRoot '文案.txt'
  if (-not (Test-Path -LiteralPath $targetScript)) {
    Copy-Item -LiteralPath $resolvedScript -Destination $targetScript
  }
}

$statePath = Join-Path $workRoot 'planning\project-state.json'
if (-not (Test-Path -LiteralPath $statePath)) {
  $state = [ordered]@{
    stage = 'initialized'
    representativeScenesApproved = $false
    characterWhitelist = 'planning/character-whitelist.txt'
    lastCheck = $null
    lastRender = $null
  }
  $state | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $statePath -Encoding UTF8
}

$skillRoot = Split-Path $PSScriptRoot -Parent
$motherSource = Join-Path $skillRoot 'assets\characters\doubao-mother.png'
$motherTarget = Join-Path $workRoot 'assets\characters\doubao-mother.png'
if ((Test-Path -LiteralPath $motherSource) -and -not (Test-Path -LiteralPath $motherTarget)) {
  Copy-Item -LiteralPath $motherSource -Destination $motherTarget
}

$whitelistPath = Join-Path $workRoot 'planning\character-whitelist.txt'
if (-not (Test-Path -LiteralPath $whitelistPath)) {
  'assets/characters/doubao-mother.png' | Set-Content -LiteralPath $whitelistPath -Encoding UTF8
}

Write-Output "Project scaffold ready: $resolvedRoot"


