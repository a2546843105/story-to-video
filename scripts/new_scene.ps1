param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectRoot,
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^scene-\d{3}$')]
  [string]$SceneId,
  [Parameter(Mandatory = $true)]
  [double]$Duration
)

if ($Duration -le 0) {
  throw 'Duration must be greater than zero.'
}

$templatePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'assets\scene-skeleton.html'
$workRoot = Join-Path $ProjectRoot '制作过程'
$sceneDir = Join-Path $workRoot 'compositions\scenes'
if (-not (Test-Path -LiteralPath $sceneDir)) {
  New-Item -ItemType Directory -Path $sceneDir -Force | Out-Null
}

$outputPath = Join-Path $sceneDir "$SceneId.html"
if (Test-Path -LiteralPath $outputPath) {
  throw "Scene already exists: $outputPath"
}

$durationText = $Duration.ToString('0.###', [System.Globalization.CultureInfo]::InvariantCulture)
$content = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
$content = $content.Replace('{{SCENE_ID}}', $SceneId).Replace('{{DURATION}}', $durationText)
Set-Content -LiteralPath $outputPath -Value $content -Encoding UTF8

Write-Output "Scene created: $outputPath"

