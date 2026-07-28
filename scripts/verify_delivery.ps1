param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectRoot,
  [double]$TargetLufs = -20,
  [double]$LoudnessTolerance = 0.5
)

$resolvedRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$requiredFiles = @(
  '文案.txt',
  '成片.mp4',
  '封面-横版4比3.jpg',
  '封面-竖版3比4.jpg',
  '发布信息.txt'
)
$errors = [System.Collections.Generic.List[string]]::new()

foreach ($name in $requiredFiles) {
  $path = Join-Path $resolvedRoot $name
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    $errors.Add("Missing deliverable: $name")
  } elseif ((Get-Item -LiteralPath $path).Length -eq 0) {
    $errors.Add("Empty deliverable: $name")
  }
}

$workRoot = Join-Path $resolvedRoot '制作过程'
if (-not (Test-Path -LiteralPath $workRoot -PathType Container)) {
  $errors.Add('Missing 制作过程 directory.')
}

$extraFiles = @(Get-ChildItem -LiteralPath $resolvedRoot -File |
  Where-Object { $requiredFiles -notcontains $_.Name })
foreach ($extra in $extraFiles) {
  $errors.Add("Unexpected root file: $($extra.Name)")
}

if ($errors.Count -eq 0) {
  $videoPath = Join-Path $resolvedRoot '成片.mp4'
  $probeText = & ffprobe -v error -show_entries stream=index,codec_name,codec_type,width,height,sample_rate,channels -show_entries format=duration,size -of json $videoPath
  if ($LASTEXITCODE -ne 0) {
    $errors.Add('ffprobe failed on 成片.mp4.')
  } else {
    $probe = $probeText | ConvertFrom-Json
    $videoStream = @($probe.streams | Where-Object { $_.codec_type -eq 'video' })[0]
    $audioStream = @($probe.streams | Where-Object { $_.codec_type -eq 'audio' })[0]
    if (-not $videoStream -or $videoStream.codec_name -ne 'h264') {
      $errors.Add('成片.mp4 must contain H.264 video.')
    }
    if ($videoStream.width -ne 1920 -or $videoStream.height -ne 1080) {
      $errors.Add("Unexpected video resolution: $($videoStream.width)x$($videoStream.height)")
    }
    if (-not $audioStream -or $audioStream.codec_name -ne 'aac') {
      $errors.Add('成片.mp4 must contain AAC audio.')
    }
    if ([int]$audioStream.sample_rate -ne 48000) {
      $errors.Add("Audio sample rate must be 48000 Hz, found $($audioStream.sample_rate).")
    }
  }

  $loudnessOutput = (& ffmpeg -hide_banner -i $videoPath -af "loudnorm=I=$TargetLufs`:TP=-1.5:LRA=11:print_format=summary" -f null NUL 2>&1) -join "`n"
  $loudnessMatch = [regex]::Match($loudnessOutput, 'Input Integrated:\s*(-?\d+(?:\.\d+)?)\s*LUFS')
  if (-not $loudnessMatch.Success) {
    $errors.Add('Could not measure integrated loudness.')
  } else {
    $measured = [double]::Parse($loudnessMatch.Groups[1].Value, [System.Globalization.CultureInfo]::InvariantCulture)
    if ([math]::Abs($measured - $TargetLufs) -gt $LoudnessTolerance) {
      $errors.Add("Integrated loudness is $measured LUFS; target is $TargetLufs ± $LoudnessTolerance.")
    }
  }
}

function Test-CoverRatio {
  param([string]$Name, [double]$ExpectedRatio)
  $path = Join-Path $resolvedRoot $Name
  if (-not (Test-Path -LiteralPath $path)) {
    return
  }
  $jsonText = & ffprobe -v error -show_entries stream=width,height -of json $path
  $cover = ($jsonText | ConvertFrom-Json).streams[0]
  if (-not $cover -or $cover.height -eq 0) {
    $errors.Add("Could not read cover dimensions: $Name")
    return
  }
  $ratio = [double]$cover.width / [double]$cover.height
  if ([math]::Abs($ratio - $ExpectedRatio) -gt 0.01) {
    $errors.Add("Wrong cover ratio for $Name`: $($cover.width)x$($cover.height)")
  }
}

Test-CoverRatio '封面-横版4比3.jpg' (4.0 / 3.0)
Test-CoverRatio '封面-竖版3比4.jpg' (3.0 / 4.0)

$publishPath = Join-Path $resolvedRoot '发布信息.txt'
if (Test-Path -LiteralPath $publishPath) {
  $publishText = Get-Content -LiteralPath $publishPath -Raw -Encoding UTF8
  $topicCount = [regex]::Matches($publishText, '(?<!\S)#[^\s#]+').Count
  if ($topicCount -ne 10) {
    $errors.Add("发布信息.txt must contain exactly 10 topics; found $topicCount.")
  }
}

if ($errors.Count -gt 0) {
  $errors | ForEach-Object { Write-Error $_ }
  exit 1
}

Write-Output "Delivery verified: five files, one process folder, valid video, covers, loudness, and 10 topics."

