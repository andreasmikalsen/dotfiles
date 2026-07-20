$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$nvimSource = Join-Path $repoRoot "nvim"
$nuSource   = Join-Path $repoRoot "nushell"

$nvimTarget = Join-Path $env:LOCALAPPDATA "nvim"
$nuTarget   = Join-Path $env:APPDATA "nushell"

function Create-Junction {
    param(
        [string]$Target,
        [string]$Source
    )

    if (Test-Path $Target) {
        Write-Host ""
        Write-Host "$Target already exists."

        $answer = Read-Host "Delete it and recreate the junction? (y/N)"

        if ($answer -notin @("y", "Y")) {
            Write-Host "Skipping."
            return
        }

        Remove-Item $Target -Recurse -Force
    }

    New-Item -ItemType Junction -Path $Target -Target $Source | Out-Null
    Write-Host "Created:"
    Write-Host "  $Target -> $Source"
}

Create-Junction $nvimTarget $nvimSource
Create-Junction $nuTarget $nuSource

Write-Host ""
Write-Host "Done!"
