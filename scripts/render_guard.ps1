param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectRoot
)

$resolvedRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
$matches = @(Get-CimInstance Win32_Process | Where-Object {
  $_.CommandLine -and
  $_.CommandLine -match 'hyperframes(\.mjs)?\s+render' -and
  $_.CommandLine.IndexOf($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
})

if ($matches.Count -gt 0) {
  $matches | Select-Object ProcessId, ParentProcessId, Name, CreationDate, CommandLine | Format-Table -AutoSize
  Write-Error 'An existing HyperFrames render is using this project. Resolve it before starting another render.'
  exit 1
}

Write-Output "Render guard passed: no active render for $resolvedRoot"

