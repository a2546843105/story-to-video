param(
  [Parameter(Mandatory = $true)]
  [string]$VideoPath,
  [Parameter(Mandatory = $true)]
  [string]$OutputPath,
  [int]$Columns = 4,
  [int]$Rows = 4
)

$resolvedVideo = (Resolve-Path -LiteralPath $VideoPath).Path
$durationText = & ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $resolvedVideo
if ($LASTEXITCODE -ne 0) {
  throw 'ffprobe failed while reading the video duration.'
}

$duration = [double]::Parse($durationText.Trim(), [System.Globalization.CultureInfo]::InvariantCulture)
$frameCount = $Columns * $Rows
$rate = $frameCount / $duration
$rateText = $rate.ToString('0.########', [System.Globalization.CultureInfo]::InvariantCulture)
$filter = "fps=$rateText,scale=480:-2,tile=${Columns}x${Rows}:padding=8:margin=8"

$outputDirectory = Split-Path -Parent $OutputPath
if ($outputDirectory) {
  New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

& ffmpeg -hide_banner -loglevel error -i $resolvedVideo -vf $filter -frames:v 1 -y $OutputPath
if ($LASTEXITCODE -ne 0) {
  throw 'ffmpeg failed while creating the contact sheet.'
}

Write-Output "Contact sheet created: $OutputPath"

