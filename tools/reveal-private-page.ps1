[CmdletBinding()]
param(
  [string] $ProtectedPath,
  [string] $OutputPath,
  [switch] $Force
)

# Unlocks the encrypted workspace.html back into the editable plaintext master
# (_papers-in-the-works.html). Mirrors the crypto in protect-private-page.ps1 and
# verify-private-page.ps1: PBKDF2-SHA256 key derivation, AES-256-GCM decryption.
# The password is typed at the prompt and never written to disk.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Resolve the repo root without relying on $PSScriptRoot, which comes back empty
# under some -File invocations of Windows PowerShell.
$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir) -and $PSCommandPath) {
  $scriptDir = Split-Path -Parent $PSCommandPath
}
if (-not [string]::IsNullOrWhiteSpace($scriptDir)) {
  $baseDir = (Resolve-Path (Join-Path $scriptDir '..')).Path
}
else {
  $baseDir = (Get-Location).Path
}
if ([string]::IsNullOrWhiteSpace($ProtectedPath)) { $ProtectedPath = Join-Path $baseDir 'workspace.html' }
if ([string]::IsNullOrWhiteSpace($OutputPath)) { $OutputPath = Join-Path $baseDir '_papers-in-the-works.html' }

function Read-WorkspacePassword {
  $securePassword = Read-Host 'Password for the private workspace' -AsSecureString
  $passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
  try {
    return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer)
  }
  finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
  }
}

if (-not (Test-Path -LiteralPath $ProtectedPath -PathType Leaf)) {
  throw "Protected page not found: $ProtectedPath"
}

$resolvedOutput = [IO.Path]::GetFullPath($OutputPath)
if ((Test-Path -LiteralPath $resolvedOutput -PathType Leaf) -and (-not $Force)) {
  throw "A master already exists at $resolvedOutput. Re-run with -Force to overwrite it."
}

$protectedPage = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $ProtectedPath))

function Read-PayloadValue([string] $Name) {
  $match = [regex]::Match($protectedPage, $Name + ":\s*'([^']+)'")
  if (-not $match.Success) {
    throw "Missing encrypted payload field: $Name"
  }
  return $match.Groups[1].Value
}

$iterationMatch = [regex]::Match($protectedPage, 'iterations:\s*(\d+)')
if (-not $iterationMatch.Success) {
  throw 'Missing PBKDF2 iteration count.'
}

$salt = [Convert]::FromBase64String((Read-PayloadValue 'salt'))
$nonce = [Convert]::FromBase64String((Read-PayloadValue 'nonce'))
$cipherText = [Convert]::FromBase64String((Read-PayloadValue 'cipherText'))
$tag = [Convert]::FromBase64String((Read-PayloadValue 'tag'))
$iterations = [int]$iterationMatch.Groups[1].Value

$password = Read-WorkspacePassword
if ([string]::IsNullOrWhiteSpace($password)) {
  throw 'The password cannot be empty.'
}

$passwordBytes = [Text.Encoding]::UTF8.GetBytes($password)
$deriver = [System.Security.Cryptography.Rfc2898DeriveBytes]::new(
  $passwordBytes,
  $salt,
  $iterations,
  [System.Security.Cryptography.HashAlgorithmName]::SHA256
)
$key = $deriver.GetBytes(32)
$plainText = [byte[]]::new($cipherText.Length)
$aes = [System.Security.Cryptography.AesGcm]::new($key, 16)

try {
  # Throws if the password is wrong (GCM authentication tag mismatch).
  $aes.Decrypt($nonce, $cipherText, $tag, $plainText)
}
catch {
  throw 'Incorrect password (the encrypted content did not authenticate).'
}
finally {
  $aes.Dispose()
  $deriver.Dispose()
  [System.Security.Cryptography.CryptographicOperations]::ZeroMemory($passwordBytes)
  [System.Security.Cryptography.CryptographicOperations]::ZeroMemory($key)
}

[IO.File]::WriteAllBytes($resolvedOutput, $plainText)
[System.Security.Cryptography.CryptographicOperations]::ZeroMemory($plainText)
$password = $null

Write-Host "Unlocked master written to $resolvedOutput"
