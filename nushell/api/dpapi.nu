param(
    [Parameter(Mandatory)]
    [ValidateSet("protect", "unprotect")]
    [string]$Mode
)

$ErrorActionPreference = "Stop"

$inputText = [Console]::In.ReadToEnd().Trim()

$entropy = [Text.Encoding]::UTF8.GetBytes(
    "nu-api-token-cache-v1"
)

if ($Mode -eq "protect") {
    $bytes = [Text.Encoding]::UTF8.GetBytes($inputText)

    $encrypted = [Security.Cryptography.ProtectedData]::Protect(
        $bytes,
        $entropy,
        [Security.Cryptography.DataProtectionScope]::CurrentUser
    )

    [Convert]::ToBase64String($encrypted)
}
else {
    $encrypted = [Convert]::FromBase64String($inputText)

    $bytes = [Security.Cryptography.ProtectedData]::Unprotect(
        $encrypted,
        $entropy,
        [Security.Cryptography.DataProtectionScope]::CurrentUser
    )

    [Text.Encoding]::UTF8.GetString($bytes)
}
