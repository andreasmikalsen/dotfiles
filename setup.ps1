# ============================================================
# Bootstrap development tools
# ============================================================

function Test-WingetPackage {
    param([string]$Id)

    $null -ne (winget list --exact --id $Id 2>$null | Select-String $Id)
}

function Ensure-WingetPackage {
    param(
        [string]$Id,
        [string]$Name = $Id,
        [string[]]$Arguments = @()
    )

    if (Test-WingetPackage $Id) {
        Write-Host "[OK] $Name already installed."
        return
    }

    Write-Host "[INSTALL] $Name..."

    winget install `
        --exact `
        --id $Id `
        --accept-package-agreements `
        --accept-source-agreements `
        @Arguments
}

function Ensure-GhExtension {
    param([string]$Name)

    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-Warning "GitHub CLI is not installed. Skipping '$Name'."
        return
    }

    if (gh extension list | Select-String $Name) {
        Write-Host "[OK] gh extension '$Name' already installed."
        return
    }

    Write-Host "[INSTALL] gh extension '$Name'..."
    gh extension install $Name
}

function Ensure-NpmGlobal {
    param([string]$Package)

    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        Write-Warning "npm is not installed. Skipping '$Package'."
        return
    }

    if (npm list -g --depth=0 2>$null | Select-String $Package) {
        Write-Host "[OK] npm package '$Package' already installed."
        return
    }

    Write-Host "[INSTALL] npm package '$Package'..."
    npm install -g $Package
}

function Install-Diffnav {
    if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
        Write-Warning "Go is not installed. Skipping diffnav."
        return
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Warning "Git is not installed. Skipping diffnav."
        return
    }

    $goBin = if ($env:GOBIN) {
        $env:GOBIN
    } else {
        (go env GOPATH).Trim() + "\bin"
    }

    $exe = Join-Path $goBin "diffnav.exe"

    if (Test-Path $exe) {
        Write-Host "[OK] diffnav already installed."
        return
    }

    $installPath = Join-Path $env:TEMP "diffnav"

    if (Test-Path $installPath) {
        Remove-Item $installPath -Recurse -Force
    }

    Write-Host "[INSTALL] diffnav..."

    git clone https://github.com/dlvhdr/diffnav.git $installPath

    Push-Location $installPath
    try {
        go install .
    }
    finally {
        Pop-Location
        Remove-Item $installPath -Recurse -Force
    }
}

function Initialize-Neovim {
    if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) {
        Write-Warning "Neovim is not installed. Skipping plugin installation."
        return
    }

    Write-Host "[SETUP] Installing Neovim plugins..."

    nvim --headless `
        "+Lazy! sync" `
        "+MasonUpdate" `
        "+qa"
}

Write-Host ""
Write-Host "=== Installing dependencies ==="
Write-Host ""

# Core tools
Ensure-WingetPackage "Neovim.Neovim" "Neovim"
Ensure-WingetPackage "zig.zig" "Zig"
Ensure-WingetPackage "Nushell.Nushell" "Nushell" @("--scope", "machine")
Ensure-WingetPackage "Starship.Starship" "Starship"
Ensure-WingetPackage "GitHub.cli" "GitHub CLI"
Ensure-WingetPackage "dandavison.delta" "delta"

# npm
Ensure-NpmGlobal "tree-sitter-cli"

# GitHub CLI extensions
Ensure-GhExtension "dlvhdr/gh-dash"

# Go tool
Install-Diffnav

Write-Host ""
Write-Host "=== Finished installing dependencies ==="

# Setup junctions
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$nvimSource   = Join-Path $repoRoot "nvim"
$nuSource     = Join-Path $repoRoot "nushell"
$ghDashSource = Join-Path $repoRoot "gh-dash"

$nvimTarget   = Join-Path $env:LOCALAPPDATA "nvim"
$nuTarget     = Join-Path $env:APPDATA "nushell"
$ghDashTarget = "~/.config/gh-dash"

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

Write-Host "=== Setup junctions ==="

Create-Junction $nvimTarget $nvimSource
Create-Junction $nuTarget $nuSource
Create-Junction $ghDashTarget $ghDashSource

Write-Host ""
Write-Host "=== Finished setting up junctions ==="

Write-Host ""
Write-Host "=== Initialize Neovim ==="

Initialize-Neovim

Write-Host ""
Write-Host "Done!"
