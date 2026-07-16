# SPDX-License-Identifier: Apache-2.0

param([Parameter(Mandatory = $true)][string]$Package)

$ErrorActionPreference = "Stop"
$ResolvedPackage = (Resolve-Path -LiteralPath $Package).Path.TrimEnd("\")
$DataRoot = Join-Path $ResolvedPackage "ProgramData\Roammand"
$Manifest = Join-Path $DataRoot "install-manifest.sha256"
$Required = @(
  "Program Files\Roammand\roammand.exe",
  "Program Files\Roammand\roammand-host-agent.exe",
  "Program Files\Roammand\roammand-privileged-bridge.exe",
  "Program Files\Roammand\roammand-session-helper.exe",
  "ProgramData\Roammand\RoammandPrivilegedBridge.xml"
)
foreach ($Relative in $Required) {
  if (-not (Test-Path -LiteralPath (Join-Path $ResolvedPackage $Relative))) {
    throw "Missing staged Windows path: $Relative"
  }
}
if (-not (Test-Path -LiteralPath $Manifest -PathType Leaf)) { throw "Missing Windows package manifest" }
if (Get-ChildItem -LiteralPath $ResolvedPackage -Recurse -Force |
    Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }) {
  throw "Reparse points are not allowed in the staged Windows package"
}

foreach ($Line in [IO.File]::ReadAllLines($Manifest)) {
  if ($Line -notmatch '^(?<Hash>[0-9A-Fa-f]{64}) \*(?<Path>.+)$') { throw "Invalid manifest line" }
  $Candidate = [IO.Path]::GetFullPath((Join-Path $ResolvedPackage $Matches.Path))
  if (-not $Candidate.StartsWith($ResolvedPackage + "\", [StringComparison]::OrdinalIgnoreCase)) {
    throw "Manifest path escapes package"
  }
  if (-not (Test-Path -LiteralPath $Candidate -PathType Leaf)) { throw "Manifest file missing" }
  $Actual = (Get-FileHash -LiteralPath $Candidate -Algorithm SHA256).Hash
  if ($Actual -ne $Matches.Hash) { throw "Manifest hash mismatch" }
}
$Bridge = Join-Path $ResolvedPackage "Program Files\Roammand\roammand-privileged-bridge.exe"
$Helper = Join-Path $ResolvedPackage "Program Files\Roammand\roammand-session-helper.exe"
& $Bridge check-windows-service | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Windows bridge role self-test failed" }
& $Helper check-windows-service | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Windows Helper role self-test failed" }
Write-Output "Windows package ok"
