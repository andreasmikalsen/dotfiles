[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

function Assert-ValidPowerShell {
    param([string]$Path)

    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $Path,
        [ref]$tokens,
        [ref]$errors
    )

    if ($errors.Count -gt 0) {
        throw "PowerShell parse errors in $Path`n$($errors | Out-String)"
    }
}

function Invoke-Nu {
    param([string]$Command)

    & nu -c $Command
    if ($LASTEXITCODE -ne 0) {
        throw "Nushell validation failed: $Command"
    }
}

Assert-ValidPowerShell (Join-Path $repoRoot "setup.ps1")
Assert-ValidPowerShell (Join-Path $repoRoot "nushell\api\dpapi.ps1")

Invoke-Nu "use ./nushell/api/auth.nu *"
Invoke-Nu "use ./nushell/api/import-postman.nu *"
Invoke-Nu "use ./nushell/db/environment.nu *"

$token = '{"access_token":"validation","expires_at":"2099-01-01T00:00:00Z"}'
$encrypted = $token | & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $repoRoot "nushell\api\dpapi.ps1") protect
$decrypted = $encrypted | & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $repoRoot "nushell\api\dpapi.ps1") unprotect

if ($decrypted.Trim() -ne $token) {
    throw "DPAPI round trip did not preserve the token payload."
}

$temporaryHome = Join-Path $env:TEMP "nu-db-validation-$([guid]::NewGuid())"

try {
    $dbCommand = @"
`$env.NU_DB_HOME = '$($temporaryHome.Replace("'", "''"))'
use ./nushell/db/environment.nu *
db init validation
db use validation | to json --raw
"@
    $status = Invoke-Nu $dbCommand | Where-Object { $_ -match '^\{' } | ConvertFrom-Json

    if ($status.database -ne "validation" -or $status.environment -ne "local") {
        throw "db use did not select the configured default environment."
    }
}
finally {
    if (Test-Path $temporaryHome) {
        Remove-Item -Recurse -Force $temporaryHome
    }
}

if (Get-Command wezterm -ErrorAction SilentlyContinue) {
    & wezterm --config-file (Join-Path $repoRoot "wezterm\wezterm.lua") show-keys | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "WezTerm configuration validation failed."
    }
}

if (Get-Command nvim -ErrorAction SilentlyContinue) {
    & nvim --headless --clean --cmd "set rtp^=$($repoRoot.Replace('\', '/'))/nvim" -u (Join-Path $repoRoot "nvim\init.lua") "+lua vim.cmd('qa')"
    if ($LASTEXITCODE -ne 0) {
        throw "Neovim configuration validation failed."
    }
}

Write-Host "Validation passed."
