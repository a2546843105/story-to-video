param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectRoot,
  [int]$ExpectedScenes = 0,
  [string[]]$SpeakerLabels = @('老板', '豆包', '管理员', '男主', '女主', '老师', '工程师')
)

$workRoot = Join-Path $ProjectRoot '制作过程'
$sceneDir = Join-Path $workRoot 'compositions\scenes'
if (-not (Test-Path -LiteralPath $sceneDir)) {
  $sceneDir = Join-Path $ProjectRoot 'compositions\scenes'
}
if (-not (Test-Path -LiteralPath $sceneDir)) {
  throw "Scene directory not found under $ProjectRoot"
}

$files = @(Get-ChildItem -LiteralPath $sceneDir -Filter 'scene-*.html' -File | Sort-Object Name)
$findings = [System.Collections.Generic.List[object]]::new()

function Add-Finding {
  param([string]$File, [string]$Rule, [string]$Detail)
  $findings.Add([pscustomobject]@{
    file = Split-Path $File -Leaf
    rule = $Rule
    detail = $Detail
  })
}

if ($ExpectedScenes -gt 0 -and $files.Count -ne $ExpectedScenes) {
  Add-Finding $sceneDir 'scene-count' "Expected $ExpectedScenes scenes, found $($files.Count)."
}

$whitelistPath = Join-Path $workRoot 'planning\character-whitelist.txt'
$whitelist = @()
if (Test-Path -LiteralPath $whitelistPath) {
  $whitelist = @(Get-Content -LiteralPath $whitelistPath -Encoding UTF8 |
    ForEach-Object { $_.Trim().Replace('\', '/') } |
    Where-Object { $_ -and -not $_.StartsWith('#') })
}

$speakerPattern = if ($SpeakerLabels.Count -gt 0) {
  '(?s)<[^>]*class=["''][^"'']*\bbubble\b[^"'']*["''][^>]*>\s*(' +
  (($SpeakerLabels | ForEach-Object { [regex]::Escape($_) }) -join '|') +
  ')\s*[:：]'
} else {
  $null
}

foreach ($file in $files) {
  $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8

  $idMatch = [regex]::Match($text, 'data-composition-id=["'']([^"'']+)["'']')
  if (-not $idMatch.Success) {
    Add-Finding $file.FullName 'composition-id' 'Missing data-composition-id.'
  } else {
    $id = [regex]::Escape($idMatch.Groups[1].Value)
    if ($text -notmatch "window\.__timelines\[['""]$id['""]\]") {
      Add-Finding $file.FullName 'timeline-registration' 'Register the timeline with a hard-coded composition id.'
    }
  }

  if ($text -match 'class=["''][^"'']*\b(num|kicker|accent)\b') {
    Add-Finding $file.FullName 'ppt-chrome' 'Repeated numbering, kicker, or accent chrome creates a PPT look.'
  }

  if ($text -match 'repeating-radial-gradient|repeating-linear-gradient') {
    Add-Finding $file.FullName 'compression-noise' 'Dense regular patterns may become dirty after platform compression.'
  }

  if ($text -match 'Microsoft YaHei|SimSun|宋体') {
    Add-Finding $file.FullName 'font' 'Use the bundled production font instead of a system fallback.'
  }

  if ($speakerPattern -and $text -match $speakerPattern) {
    Add-Finding $file.FullName 'speaker-label' 'Speech bubble starts with a speaker label.'
  }

  if ($whitelist.Count -gt 0) {
    $assetMatches = [regex]::Matches($text, 'src=["'']([^"'']*assets/characters/[^"'']+)["'']')
    foreach ($assetMatch in $assetMatches) {
      $asset = $assetMatch.Groups[1].Value.Replace('\', '/')
      if ($whitelist -notcontains $asset) {
        Add-Finding $file.FullName 'character-whitelist' "Unapproved recurring-character asset: $asset"
      }
    }
  }
}

if ($findings.Count -gt 0) {
  $findings | Sort-Object file, rule | Format-Table -AutoSize
  Write-Error "Visual gate failed with $($findings.Count) finding(s)."
  exit 1
}

Write-Output "Visual gate passed for $($files.Count) scenes."

