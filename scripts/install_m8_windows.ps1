# SPDX-License-Identifier: Apache-2.0

param(
  [string]$Package = "",
  [switch]$WhatIf
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($Package)) { $Package = Join-Path $Root "dist\m8-windows" }
& (Join-Path $PSScriptRoot "check_m8_windows_package.ps1") -Package $Package | Out-Null
if ($WhatIf) {
  Write-Output "Would install verified app, GUI-managed Host Agent, LocalSystem bridge, Helper, restricted service data, and recovery policy; no changes made"
  exit 0
}

$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  throw "Administrator privileges are required; rerun as administrator or use -WhatIf"
}

$ServiceName = "RoammandPrivilegedBridge"
$InstallRoot = Join-Path $env:ProgramFiles "Roammand"
$DataRoot = Join-Path $env:ProgramData "Roammand"
$LegacyInstallRoot = Join-Path $env:ProgramFiles "Roammand"
$LegacyDataRoot = Join-Path $env:ProgramData "Roammand"
$ServiceExecutable = Join-Path $InstallRoot "roammand-privileged-bridge.exe"
$SecretPath = Join-Path $DataRoot "bridge-install-secret.bin"
$OwnerSidPath = Join-Path $DataRoot "bridge-owner-sid.txt"
$StagedProgram = Join-Path $Package "Program Files\Roammand"
$StagedData = Join-Path $Package "ProgramData\Roammand"

$Existing = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($null -ne $Existing) {
  if ($Existing.Status -ne "Stopped") { Stop-Service -Name $ServiceName -Force }
}
Remove-Item -LiteralPath $LegacyInstallRoot -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $LegacyDataRoot -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $InstallRoot, $DataRoot | Out-Null
Copy-Item -Path (Join-Path $StagedProgram "*") -Destination $InstallRoot -Recurse -Force
Copy-Item -Path (Join-Path $StagedData "*") -Destination $DataRoot -Recurse -Force
if ($null -eq $Existing) {
  New-Service -Name $ServiceName -DisplayName "Roammand Privileged Bridge" `
    -BinaryPathName "`"$ServiceExecutable`"" -StartupType Automatic | Out-Null
}

$Secret = New-Object byte[] 32
$Generator = [Security.Cryptography.RandomNumberGenerator]::Create()
try { $Generator.GetBytes($Secret) } finally { $Generator.Dispose() }
[IO.File]::WriteAllBytes($SecretPath, $Secret)
[Array]::Clear($Secret, 0, $Secret.Length)
$OwnerSid = $Identity.User.Value
[IO.File]::WriteAllText($OwnerSidPath, "$OwnerSid`n", (New-Object Text.UTF8Encoding($false)))
& icacls.exe $DataRoot /inheritance:r /grant:r "SYSTEM:(OI)(CI)F" "Administrators:(OI)(CI)F" | Out-Null
& icacls.exe $SecretPath /inheritance:r /grant:r "SYSTEM:F" "Administrators:F" "${OwnerSid}:R" | Out-Null
& sc.exe config $ServiceName "binPath= `"$ServiceExecutable`"" "start= auto" "obj= LocalSystem" | Out-Null
& sc.exe failure $ServiceName "reset= 86400" "actions= restart/5000/restart/15000/restart/30000" | Out-Null
& sc.exe failureflag $ServiceName 1 | Out-Null
Start-Service -Name $ServiceName
Write-Output "Windows Host components installed; open Roammand to start its Host Agent"
