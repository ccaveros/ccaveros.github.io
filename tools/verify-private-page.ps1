[CmdletBinding()]
param(
  [string] $SourcePath = (Join-Path $PSScriptRoot '..\_papers-in-the-works.html'),
  [string] $ProtectedPath = (Join-Path $PSScriptRoot '..\workspace.html'),
  [Parameter(Mandatory = $true)]
  [string] $SecretPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$protectedPage = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $ProtectedPath))
$password = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $SecretPath))
$expected = [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $SourcePath))

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
$passwordBytes = [Text.Encoding]::UTF8.GetBytes($password)
$deriver = [System.Security.Cryptography.Rfc2898DeriveBytes]::new(
  $passwordBytes,
  $salt,
  $iterations,
  [System.Security.Cryptography.HashAlgorithmName]::SHA256
)
$key = $deriver.GetBytes(32)
$actual = [byte[]]::new($cipherText.Length)
$aes = [System.Security.Cryptography.AesGcm]::new($key, 16)

try {
  $aes.Decrypt($nonce, $cipherText, $tag, $actual)
  if (-not [System.Security.Cryptography.CryptographicOperations]::FixedTimeEquals($expected, $actual)) {
    throw 'The decrypted page does not match the private source.'
  }
}
finally {
  $aes.Dispose()
  $deriver.Dispose()
  [System.Security.Cryptography.CryptographicOperations]::ZeroMemory($passwordBytes)
  [System.Security.Cryptography.CryptographicOperations]::ZeroMemory($key)
  [System.Security.Cryptography.CryptographicOperations]::ZeroMemory($actual)
  [System.Security.Cryptography.CryptographicOperations]::ZeroMemory($expected)
}

if ($protectedPage.Contains('Nonintervention as Political Action') -or
    $protectedPage.Contains('Keeping Data Alive')) {
  throw 'Readable private project text was found in the protected page.'
}

Write-Host 'Verified: the password decrypts the exact source and the deployed file contains no checked plaintext titles.'
