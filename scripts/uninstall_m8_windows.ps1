# SPDX-License-Identifier: Apache-2.0

param([switch]$WhatIf)

$ErrorActionPreference = "Stop"
if ($WhatIf) {
  Write-Output "Would stop and delete the service and program data; preserve each user's local identity and grants; no changes made"
  exit 0
}
$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  throw "Administrator privileges are required; rerun as administrator or use -WhatIf"
}

$ServiceName = "RoammandPrivilegedBridge"
$Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($null -ne $Service) {
  if ($Service.Status -ne "Stopped") { Stop-Service -Name $ServiceName -Force }
  & sc.exe delete $ServiceName | Out-Null
}
foreach ($ProductDirectory in @("Roammand", "Roammand")) {
  Remove-Item -LiteralPath (Join-Path $env:ProgramFiles $ProductDirectory) -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath (Join-Path $env:ProgramData $ProductDirectory) -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Output "Windows program files removed; local identity and grants were preserved"
