# ============================================================
# Bootstrap development environment
# ============================================================

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path


# ============================================================
# Environment helpers
# ============================================================

function Refresh-Path {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")

    $paths = @(
        $env:Path -split ";"
        $machinePath -split ";"
        $userPath -split ";"
    ) |
        Where-Object { $_ } |
        Select-Object -Unique

    $env:Path = $paths -join ";"
}

function Ensure-UserPathEntry {
    param([string]$Path)

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $entries = @($userPath -split ";" | Where-Object { $_ })

    $exists = $entries | Where-Object {
        $_.TrimEnd("\") -ieq $Path.TrimEnd("\")
    }

    if ($exists) {
        return
    }

    $newPath = (@($entries) + $Path) -join ";"

    [Environment]::SetEnvironmentVariable(
        "Path",
        $newPath,
        "User"
    )

    Refresh-Path
}


# ============================================================
# WinGet
# ============================================================

function Test-WingetPackage {
    param([string]$Id)

    $result = winget list --exact --id $Id 2>$null
    $null -ne ($result | Select-String -SimpleMatch $Id)
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

    $wingetArgs = @(
        "install"
        "--exact"
        "--id", $Id
        "--accept-package-agreements"
        "--accept-source-agreements"
    ) + $Arguments

    & winget @wingetArgs

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install $Name."
    }

    Refresh-Path
}


# ============================================================
# MSVC Build Tools
# ============================================================

function Test-MsvcBuildTools {
    $vswhere = Join-Path `
        ${env:ProgramFiles(x86)} `
        "Microsoft Visual Studio\Installer\vswhere.exe"

    if (-not (Test-Path $vswhere)) {
        return $false
    }

    $installation = & $vswhere `
        -latest `
        -products * `
        -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
        -property installationPath

    return -not [string]::IsNullOrWhiteSpace(
        ($installation | Select-Object -First 1)
    )
}

function Ensure-MsvcBuildTools {
    if (Test-MsvcBuildTools) {
        Write-Host "[OK] MSVC C++ Build Tools already installed."
        return
    }

    Write-Host "[INSTALL] Visual Studio C++ Build Tools..."

    $vswhere = Join-Path `
        ${env:ProgramFiles(x86)} `
        "Microsoft Visual Studio\Installer\vswhere.exe"

    $setup = Join-Path `
        ${env:ProgramFiles(x86)} `
        "Microsoft Visual Studio\Installer\setup.exe"

    # Check whether Build Tools itself already exists but lacks C++.
    $buildToolsPath = $null

    if (Test-Path $vswhere) {
        $buildToolsPath = & $vswhere `
            -latest `
            -products Microsoft.VisualStudio.Product.BuildTools `
            -property installationPath
    }

    if ($buildToolsPath -and (Test-Path $setup)) {
        # Modify an existing Build Tools installation.
        & $setup modify `
            --installPath $buildToolsPath `
            --add Microsoft.VisualStudio.Workload.VCTools `
            --includeRecommended `
            --passive `
            --norestart

        if ($LASTEXITCODE -notin @(0, 3010)) {
            throw "Failed to add the MSVC C++ workload."
        }
    }
    else {
        # Install Build Tools and the C++ workload.
        winget install `
            --exact `
            --id Microsoft.VisualStudio.2022.BuildTools `
            --accept-package-agreements `
            --accept-source-agreements `
            --override "--passive --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"

        if ($LASTEXITCODE -ne 0) {
            throw "Visual Studio C++ Build Tools installation failed."
        }
    }

    if (-not (Test-MsvcBuildTools)) {
        throw "MSVC C++ Build Tools could not be detected after installation."
    }

    Write-Host "[OK] MSVC C++ Build Tools installed."
}

# ============================================================
# Rust / Cargo
# ============================================================

function Ensure-Cargo {
    if (Get-Command cargo -ErrorAction SilentlyContinue) {
        Write-Host "[OK] Cargo already installed."
        return
    }

    Write-Host "[INSTALL] Rust/Cargo..."

    Ensure-WingetPackage "Rustlang.Rustup" "Rustup"

    $cargoBin = Join-Path $env:USERPROFILE ".cargo\bin"
    Ensure-UserPathEntry $cargoBin

    Refresh-Path

    if (-not (Get-Command rustup -ErrorAction SilentlyContinue)) {
        throw "Rustup installation failed."
    }

    rustup default stable

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install the stable Rust toolchain."
    }

    Refresh-Path

    if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
        throw "Cargo installation failed."
    }
}

function Ensure-CargoPackage {
    param(
        [string]$Package,
        [string]$Command = $Package
    )

    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        Write-Host "[OK] $Package already installed."
        return
    }

    Ensure-MsvcBuildTools
    Ensure-Cargo

    Write-Host "[INSTALL] $Package..."

    cargo install $Package

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install Cargo package '$Package'."
    }

    Refresh-Path
}


# ============================================================
# GitHub CLI extensions
# ============================================================

function Ensure-GhExtension {
    param([string]$Name)

    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw "GitHub CLI is not installed."
    }

    if (gh extension list | Select-String -SimpleMatch $Name) {
        Write-Host "[OK] gh extension '$Name' already installed."
        return
    }

    Write-Host "[INSTALL] gh extension '$Name'..."

    gh extension install $Name

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install gh extension '$Name'."
    }
}


# ============================================================
# diffnav
# ============================================================

function Ensure-Diffnav {
    if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
        throw "Go is not installed."
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "Git is not installed."
    }

    $goBin = if ($env:GOBIN) {
        $env:GOBIN
    }
    else {
        Join-Path (go env GOPATH).Trim() "bin"
    }

    Ensure-UserPathEntry $goBin

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

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to clone diffnav."
    }

    Push-Location $installPath

    try {
        go install .

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to install diffnav."
        }
    }
    finally {
        Pop-Location

        if (Test-Path $installPath) {
            Remove-Item $installPath -Recurse -Force
        }
    }

    Refresh-Path
}

# ============================================================
# Git configuration
# ============================================================

function Ensure-GitAlias {
    param(
        [string]$Name,
        [string]$Command
    )

    $current = git config --global --get "alias.$Name" 2>$null

    if ($current -eq $Command) {
        Write-Host "[OK] Git alias '$Name' already configured."
        return
    }

    Write-Host "[CONFIG] git $Name -> $Command"
    git config --global "alias.$Name" $Command
}


# ============================================================
# Junctions
# ============================================================

function Create-Junction {
    param(
        [string]$Target,
        [string]$Source
    )

    $sourceFull = [IO.Path]::GetFullPath($Source)

    $item = Get-Item `
        -LiteralPath $Target `
        -Force `
        -ErrorAction SilentlyContinue

    if ($item) {
        $isLink = $item.Attributes -band [IO.FileAttributes]::ReparsePoint

        if ($isLink -and $item.Target) {
            $existingTarget = [IO.Path]::GetFullPath(
                [string]$item.Target
            )

            if (
                $existingTarget.TrimEnd("\") -ieq
                $sourceFull.TrimEnd("\")
            ) {
                Write-Host "[OK] Junction already exists:"
                Write-Host "  $Target -> $Source"
                return
            }
        }

        Write-Host ""
        Write-Host "$Target already exists."

        $answer = Read-Host "Delete it and recreate the junction? (y/N)"

        if ($answer -notin @("y", "Y")) {
            Write-Host "Skipping."
            return
        }

        Remove-Item $Target -Recurse -Force
    }

    $parent = Split-Path -Parent $Target

    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    New-Item `
        -ItemType Junction `
        -Path $Target `
        -Target $Source |
        Out-Null

    Write-Host "[OK] Created junction:"
    Write-Host "  $Target -> $Source"
}


# ============================================================
# Neovim
# ============================================================

function Initialize-Neovim {
    if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) {
        throw "Neovim is not installed."
    }

    Write-Host "[SETUP] Installing Neovim plugins..."

    nvim --headless `
        "+Lazy! sync" `
        "+qa"

    if ($LASTEXITCODE -ne 0) {
        throw "Neovim plugin installation failed."
    }

    Write-Host "[SETUP] Installing Mason tools..."

    nvim --headless `
        "+MasonToolsInstallSync" `
        "+qa"

    if ($LASTEXITCODE -ne 0) {
        throw "Mason tool installation failed."
    }
}

# ============================================================
# Environment
# ============================================================

$env:DOTFILES = $repoRoot

[Environment]::SetEnvironmentVariable(
    "DOTFILES",
    $repoRoot,
    "User"
)

# ============================================================
# Setup nu-api
# ============================================================

$apiHome = Join-Path $env:LOCALAPPDATA "nu-api"

$env:NU_API_HOME = $apiHome

[Environment]::SetEnvironmentVariable(
    "NU_API_HOME",
    $apiHome,
    "User"
)

New-Item `
    -ItemType Directory `
    -Force `
    -Path $apiHome |
    Out-Null

New-Item `
    -ItemType Directory `
    -Force `
    -Path (Join-Path $apiHome "collections") |
    Out-Null

New-Item `
    -ItemType Directory `
    -Force `
    -Path (Join-Path $apiHome "state\tokens") |
    Out-Null

# ============================================================
# Install dependencies
# ============================================================

Write-Host ""
Write-Host "=== Installing dependencies ==="
Write-Host ""

# Core
Ensure-WingetPackage "Git.Git" "Git"
Ensure-WingetPackage "Neovim.Neovim" "Neovim"
Ensure-WingetPackage "Nushell.Nushell" "Nushell" @("--scope", "machine")
Ensure-WingetPackage "Starship.Starship" "Starship"
Ensure-WingetPackage "GitHub.cli" "GitHub CLI"
Ensure-WingetPackage "dandavison.delta" "Delta"
Ensure-WingetPackage "wez.wezterm" "WezTerm"
Ensure-WingetPackage "GoLang.Go" "Go"

Refresh-Path

# Rust / C++ toolchain
Ensure-MsvcBuildTools
Ensure-Cargo

# Cargo tools
Ensure-CargoPackage "tree-sitter-cli" "tree-sitter"
Ensure-CargoPackage "gh-review" "gh-review"

# GitHub
Ensure-GhExtension "dlvhdr/gh-dash"

# Go tools
Ensure-Diffnav

# Git configuration
Ensure-GitAlias "c" "checkout"

Write-Host ""
Write-Host "=== Finished installing dependencies ==="


# ============================================================
# Junctions
# ============================================================

$nvimSource    = Join-Path $repoRoot "nvim"
$nuSource      = Join-Path $repoRoot "nushell"
$ghDashSource  = Join-Path $repoRoot "gh-dash"
$weztermSource = Join-Path $repoRoot "wezterm"

$nvimTarget    = Join-Path $env:LOCALAPPDATA "nvim"
$nuTarget      = Join-Path $env:APPDATA "nushell"
$ghDashTarget  = Join-Path $env:USERPROFILE ".config\gh-dash"
$weztermTarget = Join-Path $env:USERPROFILE ".config\wezterm"

Write-Host ""
Write-Host "=== Setting up junctions ==="
Write-Host ""

Create-Junction $nvimTarget $nvimSource
Create-Junction $nuTarget $nuSource
Create-Junction $ghDashTarget $ghDashSource
Create-Junction $weztermTarget $weztermSource

Write-Host ""
Write-Host "=== Finished setting up junctions ==="


# ============================================================
# Neovim
# ============================================================

Write-Host ""
Write-Host "=== Initializing Neovim ==="
Write-Host ""

Initialize-Neovim

Write-Host ""
Write-Host "=== Setup complete ==="
Write-Host ""
