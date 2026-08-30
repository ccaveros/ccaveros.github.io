[CmdletBinding(DefaultParameterSetName = 'Prompt')]
param(
  [string] $SourcePath = (Join-Path $PSScriptRoot '..\_papers-in-the-works.html'),
  [string] $OutputPath = (Join-Path $PSScriptRoot '..\workspace.html'),
  [Parameter(ParameterSetName = 'Generated')]
  [switch] $GeneratePassword,
  [Parameter(ParameterSetName = 'Generated')]
  [string] $SecretOutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-WorkspacePassword {
  $randomBytes = [byte[]]::new(24)
  [System.Security.Cryptography.RandomNumberGenerator]::Fill($randomBytes)
  return [Convert]::ToBase64String($randomBytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
}

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

if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
  throw "Private source page not found: $SourcePath"
}

if ($GeneratePassword) {
  if ([string]::IsNullOrWhiteSpace($SecretOutputPath)) {
    throw 'SecretOutputPath is required when GeneratePassword is used.'
  }
  $password = New-WorkspacePassword
}
else {
  $password = Read-WorkspacePassword
  if ([string]::IsNullOrWhiteSpace($password)) {
    throw 'The password cannot be empty.'
  }
}

$plainText = [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $SourcePath))
$salt = [byte[]]::new(16)
$nonce = [byte[]]::new(12)
[System.Security.Cryptography.RandomNumberGenerator]::Fill($salt)
[System.Security.Cryptography.RandomNumberGenerator]::Fill($nonce)

$iterations = 600000
$passwordBytes = [Text.Encoding]::UTF8.GetBytes($password)
$deriver = [System.Security.Cryptography.Rfc2898DeriveBytes]::new(
  $passwordBytes,
  $salt,
  $iterations,
  [System.Security.Cryptography.HashAlgorithmName]::SHA256
)
$key = $deriver.GetBytes(32)
$cipherText = [byte[]]::new($plainText.Length)
$tag = [byte[]]::new(16)
$aes = [System.Security.Cryptography.AesGcm]::new($key, 16)

try {
  $aes.Encrypt($nonce, $plainText, $cipherText, $tag)
}
finally {
  $aes.Dispose()
  $deriver.Dispose()
  [System.Security.Cryptography.CryptographicOperations]::ZeroMemory($passwordBytes)
  [System.Security.Cryptography.CryptographicOperations]::ZeroMemory($key)
  [System.Security.Cryptography.CryptographicOperations]::ZeroMemory($plainText)
}

$salt64 = [Convert]::ToBase64String($salt)
$nonce64 = [Convert]::ToBase64String($nonce)
$cipher64 = [Convert]::ToBase64String($cipherText)
$tag64 = [Convert]::ToBase64String($tag)

$pageTemplate = @'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="robots" content="noindex, nofollow, noarchive">
  <meta name="referrer" content="no-referrer">
  <title>Private workspace · Cecilia Cavero</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Libre+Caslon+Display&family=Libre+Caslon+Text:ital,wght@0,400;0,700;1,400&display=swap" rel="stylesheet">
  <style>
    :root { --paper:#E4D8BD; --ink:#171309; --ink-2:#4A4230; --accent:#7E2E0B; }
    * { box-sizing:border-box; border-radius:0; }
    body { margin:0; min-height:100vh; background:var(--paper); color:var(--ink); font:17px/1.6 'Libre Caslon Text',Georgia,serif; }
    main { width:min(100% - 2.5rem, 520px); margin:0 auto; padding:12vh 0 4rem; }
    .name { margin:0 0 .5rem; padding-bottom:.65rem; border-bottom:3px solid var(--ink); font:400 1.05rem/1.2 'Libre Caslon Display','Libre Caslon Text',Georgia,serif; }
    h1 { margin:3rem 0 .6rem; color:var(--accent); font:400 2rem/1.08 'Libre Caslon Display','Libre Caslon Text',Georgia,serif; }
    .intro { max-width:38ch; margin:0 0 2rem; color:var(--ink-2); font-size:.94rem; }
    label { display:block; margin-bottom:.4rem; color:var(--ink-2); font-size:.84rem; }
    .controls { display:grid; grid-template-columns:1fr auto; gap:.65rem; }
    input, button { min-height:44px; border:1px solid var(--ink); background:transparent; color:var(--ink); font:inherit; }
    input { width:100%; padding:.55rem .65rem; }
    button { padding:.55rem .9rem; cursor:pointer; }
    button:hover, button:focus-visible { border-color:var(--accent); color:var(--accent); }
    input:focus-visible { outline:2px solid var(--accent); outline-offset:2px; }
    button:disabled { cursor:wait; opacity:.55; }
    #message { min-height:1.5rem; margin:.6rem 0 0; color:var(--accent); font-size:.82rem; }
    .back { display:inline-block; margin-top:2.5rem; color:var(--ink-2); font-size:.82rem; text-decoration:none; }
    .back:hover { color:var(--accent); }
    @media (prefers-color-scheme:dark) {
      :root { --paper:#1A1816; --ink:#EDE7DC; --ink-2:#ADA396; --accent:#E08B5C; }
    }
    @media (max-width:520px) { .controls { grid-template-columns:1fr; } button { width:100%; } }
  </style>
</head>
<body>
  <main>
    <p class="name">Cecilia Cavero</p>
    <h1>Private workspace</h1>
    <p class="intro">Working research notes. Enter the shared password to continue.</p>
    <form id="unlock-form">
      <label for="workspace-password">Password</label>
      <div class="controls">
        <input id="workspace-password" name="password" type="password" autocomplete="current-password" required autofocus>
        <button id="unlock-button" type="submit">Open</button>
      </div>
      <p id="message" role="status" aria-live="polite"></p>
    </form>
    <noscript>JavaScript is required to unlock this page.</noscript>
    <a class="back" href="index.html">Return to website</a>
  </main>
  <script>
    const payload = Object.freeze({
      iterations: __ITERATIONS__,
      salt: '__SALT__',
      nonce: '__NONCE__',
      cipherText: '__CIPHER__',
      tag: '__TAG__'
    });

    const fromBase64 = (value) => Uint8Array.from(atob(value), (character) => character.charCodeAt(0));

    document.getElementById('unlock-form').addEventListener('submit', async (event) => {
      event.preventDefault();
      const passwordInput = document.getElementById('workspace-password');
      const button = document.getElementById('unlock-button');
      const message = document.getElementById('message');
      button.disabled = true;
      message.textContent = 'Opening...';

      try {
        const passwordMaterial = await crypto.subtle.importKey(
          'raw',
          new TextEncoder().encode(passwordInput.value),
          'PBKDF2',
          false,
          ['deriveKey']
        );
        const key = await crypto.subtle.deriveKey(
          { name:'PBKDF2', salt:fromBase64(payload.salt), iterations:payload.iterations, hash:'SHA-256' },
          passwordMaterial,
          { name:'AES-GCM', length:256 },
          false,
          ['decrypt']
        );
        const cipherText = fromBase64(payload.cipherText);
        const tag = fromBase64(payload.tag);
        const sealed = new Uint8Array(cipherText.length + tag.length);
        sealed.set(cipherText);
        sealed.set(tag, cipherText.length);
        const plainText = await crypto.subtle.decrypt(
          { name:'AES-GCM', iv:fromBase64(payload.nonce), tagLength:128 },
          key,
          sealed
        );
        const privatePage = new TextDecoder().decode(plainText);
        passwordInput.value = '';
        document.open();
        document.write(privatePage);
        document.close();
      }
      catch (error) {
        passwordInput.value = '';
        passwordInput.focus();
        message.textContent = 'Incorrect password.';
        button.disabled = false;
      }
    });
  </script>
</body>
</html>
'@

$protectedPage = $pageTemplate.
  Replace('__ITERATIONS__', [string]$iterations).
  Replace('__SALT__', $salt64).
  Replace('__NONCE__', $nonce64).
  Replace('__CIPHER__', $cipher64).
  Replace('__TAG__', $tag64)

$resolvedOutput = [IO.Path]::GetFullPath($OutputPath)
[IO.File]::WriteAllText($resolvedOutput, $protectedPage, [Text.UTF8Encoding]::new($false))

if ($GeneratePassword) {
  $resolvedSecretOutput = [IO.Path]::GetFullPath($SecretOutputPath)
  [IO.File]::WriteAllText($resolvedSecretOutput, $password, [Text.UTF8Encoding]::new($false))
}

$password = $null
Write-Host "Protected page written to $resolvedOutput"
