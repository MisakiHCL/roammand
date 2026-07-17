# SPDX-License-Identifier: Apache-2.0

param(
  [string]$Output = "",
  [string]$AppDirectory = "",
  [string]$HostAgent = "",
  [string]$Bridge = "",
  [string]$SessionHelper = ""
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($Output)) {
  $Output = Join-Path $Root "dist\m8-windows"
}
$Overrides = @($AppDirectory, $HostAgent, $Bridge, $SessionHelper) |
  Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

if ($Overrides.Count -eq 0) {
  Push-Location $Root
  try {
    if (-not [string]::IsNullOrWhiteSpace((git status --porcelain --untracked-files=normal))) {
      throw "Refusing release build from a dirty worktree"
    }
    $WebRtcRoot = (& bash "./scripts/fetch_libwebrtc.sh").Trim()
    if ([string]::IsNullOrWhiteSpace($WebRtcRoot)) { throw "Native WebRTC runtime is unavailable" }
    $env:LK_CUSTOM_WEBRTC = $WebRtcRoot
    cargo build --release -p roammand-host-agent --features native-webrtc
    cargo build --release -p roammand-privileged-bridge --features native-webrtc
    Push-Location "apps\client_flutter"
    try { flutter build windows --release } finally { Pop-Location }
  } finally {
    Pop-Location
  }
  $AppDirectory = Join-Path $Root "apps\client_flutter\build\windows\x64\runner\Release"
  $HostAgent = Join-Path $Root "target\release\roammand-host-agent.exe"
  $Bridge = Join-Path $Root "target\release\roammand-privileged-bridge.exe"
  $SessionHelper = $Bridge
} elseif ($Overrides.Count -ne 4) {
  throw "All four artifact overrides are required together"
}

foreach ($Artifact in @($AppDirectory, $HostAgent, $Bridge, $SessionHelper)) {
  if (-not (Test-Path -LiteralPath $Artifact)) { throw "Missing package artifact" }
}

if (Test-Path -LiteralPath $Output) { Remove-Item -LiteralPath $Output -Recurse -Force }
$ProgramRoot = Join-Path $Output "Program Files\Roammand"
$DataRoot = Join-Path $Output "ProgramData\Roammand"
New-Item -ItemType Directory -Force -Path $ProgramRoot, (Join-Path $DataRoot "licenses") | Out-Null
Copy-Item -Path (Join-Path $AppDirectory "*") -Destination $ProgramRoot -Recurse -Force
Copy-Item -LiteralPath $HostAgent -Destination (Join-Path $ProgramRoot "roammand-host-agent.exe")
Copy-Item -LiteralPath $Bridge -Destination (Join-Path $ProgramRoot "roammand-privileged-bridge.exe")
Copy-Item -LiteralPath $SessionHelper -Destination (Join-Path $ProgramRoot "roammand-session-helper.exe")
Copy-Item -LiteralPath (Join-Path $Root "packaging\windows\RoammandPrivilegedBridge.xml") -Destination $DataRoot
Copy-Item -LiteralPath (Join-Path $Root "licenses\MPL-2.0.txt") -Destination (Join-Path $DataRoot "licenses")
Copy-Item -LiteralPath (Join-Path $Root "licenses\Apache-2.0.txt") -Destination (Join-Path $DataRoot "licenses")

$Manifest = Join-Path $DataRoot "install-manifest.sha256"
$OutputDirectory = Get-Item -LiteralPath $Output
$ResolvedOutput = $OutputDirectory.FullName.TrimEnd([IO.Path]::DirectorySeparatorChar)
$Lines = $OutputDirectory.EnumerateFiles("*", [IO.SearchOption]::AllDirectories) |
  Where-Object { $_.FullName -ne $Manifest } |
  ForEach-Object {
    $Relative = [IO.Path]::GetRelativePath($ResolvedOutput, $_.FullName)
    $Hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    "$Hash *$Relative"
  } | Sort-Object
[IO.File]::WriteAllLines($Manifest, [string[]]$Lines, (New-Object Text.UTF8Encoding($false)))
Write-Output "Staged Windows package: $Output"
