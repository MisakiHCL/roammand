# SPDX-License-Identifier: Apache-2.0

param([Parameter(Mandatory = $true)][string]$Package)

$ErrorActionPreference = "Stop"
$PackageDirectory = Get-Item -LiteralPath $Package
$ResolvedPackage = $PackageDirectory.FullName.TrimEnd([IO.Path]::DirectorySeparatorChar)
$DataRoot = Join-Path $ResolvedPackage "ProgramData\Roammand"
$Manifest = Join-Path $DataRoot "install-manifest.sha256"
$ManifestLinePattern = '^(?<Hash>[0-9A-Fa-f]{64}) \*(?<Path>.+)$'
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
  if (-not ($Line -match $ManifestLinePattern)) { throw "Invalid manifest line" }
  $ExpectedHash = $Matches['Hash']
  $ManifestPath = $Matches['Path']
  if ([IO.Path]::IsPathRooted($ManifestPath)) { throw "Manifest path escapes package" }
  $Candidate = [IO.Path]::GetFullPath((Join-Path $ResolvedPackage $ManifestPath))
  $RelativeCandidate = [IO.Path]::GetRelativePath($ResolvedPackage, $Candidate)
  $ParentDirectory = ".."
  $ParentPrefix = $ParentDirectory + [IO.Path]::DirectorySeparatorChar
  if ([IO.Path]::IsPathRooted($RelativeCandidate) -or
      $RelativeCandidate -eq $ParentDirectory -or
      $RelativeCandidate.StartsWith($ParentPrefix, [StringComparison]::Ordinal)) {
    throw "Manifest path escapes package"
  }
  if (-not (Test-Path -LiteralPath $Candidate -PathType Leaf)) { throw "Manifest file missing" }
  $Actual = (Get-FileHash -LiteralPath $Candidate -Algorithm SHA256).Hash
  if ($Actual -ne $ExpectedHash) { throw "Manifest hash mismatch" }
}
$Bridge = Join-Path $ResolvedPackage "Program Files\Roammand\roammand-privileged-bridge.exe"
$Helper = Join-Path $ResolvedPackage "Program Files\Roammand\roammand-session-helper.exe"
& $Bridge check-windows-service | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Windows bridge role self-test failed" }
& $Helper check-windows-service | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Windows Helper role self-test failed" }
Write-Output "Windows package ok"
