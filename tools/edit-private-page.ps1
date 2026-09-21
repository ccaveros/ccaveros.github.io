[CmdletBinding()]
param(
  [string] $MasterPath,
  [string] $ProtectedPath,
  [string] $Editor
)

# One command edit loop for the private workspace page.
#   1. If the plaintext master is missing, unlock workspace.html (asks password).
#   2. Open the master in an editor and wait for you to save and close it.
#   3. Re-encrypt the master back into workspace.html (asks password).
# The master (_papers-in-the-works.html) is gitignored, so it stays local. Leaving
# it on disk is what makes the next edit a single step: just run this again.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Resolve the tools directory without relying on $PSScriptRoot, which comes back
# empty under some -File invocations of Windows PowerShell.
$toolsDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($toolsDir) -and $PSCommandPath) {
  $toolsDir = Split-Path -Parent $PSCommandPath
}
if ([string]::IsNullOrWhiteSpace($toolsDir)) {
  $toolsDir = Join-Path (Get-Location).Path 'tools'
}
$baseDir = (Resolve-Path (Join-Path $toolsDir '..')).Path
if ([string]::IsNullOrWhiteSpace($MasterPath)) { $MasterPath = Join-Path $baseDir '_papers-in-the-works.html' }
if ([string]::IsNullOrWhiteSpace($ProtectedPath)) { $ProtectedPath = Join-Path $baseDir 'workspace.html' }

$reveal = Join-Path $toolsDir 'reveal-private-page.ps1'
$protect = Join-Path $toolsDir 'protect-private-page.ps1'

# 1. Ensure the editable master exists.
if (-not (Test-Path -LiteralPath $MasterPath -PathType Leaf)) {
  Write-Host 'No editable master found. Unlocking workspace.html first.'
  & $reveal -ProtectedPath $ProtectedPath -OutputPath $MasterPath
}

$masterFull = (Resolve-Path -LiteralPath $MasterPath).Path

# 2. Open for editing and wait until you are done.
if ([string]::IsNullOrWhiteSpace($Editor)) {
  if (Get-Command code -ErrorAction SilentlyContinue) {
    Start-Process -FilePath 'code' -ArgumentList '--wait', $masterFull -Wait
  }
  else {
    Start-Process -FilePath 'notepad.exe' -ArgumentList $masterFull -Wait
  }
}
else {
  Start-Process -FilePath $Editor -ArgumentList $masterFull -Wait
}

Read-Host 'When you have saved and closed the file, press Enter to re-lock and rebuild workspace.html'

# 3. Re-encrypt with the existing protect tool (asks for the password).
& $protect -SourcePath $MasterPath -OutputPath $ProtectedPath

Write-Host ''
Write-Host 'workspace.html rebuilt. To publish, run:'
Write-Host '  git add workspace.html; git commit -m "Update private workspace"; git push'
