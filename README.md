# Windows Dotfiles

Personal Windows development environment centered on Nushell, Neovim, and WezTerm.

## Included configuration

- Nushell with API, database, Podman, and observability command modules.
- Neovim with lazy.nvim, Mason, LSP, formatting, Git, and database tooling.
- WezTerm, Starship, Yazi, gh-dash, and spotify-player.
- A bundled FiraCode Nerd Font, installed by setup for the current user.

## Requirements

- Windows 10 or 11 with PowerShell 5.1 and WinGet.
- Internet access for package and plugin installation.
- Run from a normal user PowerShell session. The Nushell package requests machine scope and may prompt for elevation.
- Go is installed automatically by setup. Do not install it separately unless you prefer to manage it yourself.

Optional commands are required only for their related Nushell modules:

- PostgreSQL: `psql`
- Redis: `redis-cli`
- Azure PostgreSQL token authentication: `az`
- Container commands: Podman

## Installation

Clone this repository, then preview the exact setup plan:

```powershell
.\setup.ps1 -WhatIf
```

Apply the setup:

```powershell
.\setup.ps1
```

The script installs command-line tools, sets user environment variables, creates private workspaces, installs the bundled font, and creates configuration junctions. It asks before replacing an existing configuration directory and moves the existing directory to a timestamped backup beside the target.

Run only selected parts when updating an existing machine:

```powershell
.\setup.ps1 -SkipToolInstall
.\setup.ps1 -SkipLinks
.\setup.ps1 -SkipNeovim
```

Restart the terminal after setup so persistent user environment variables are available everywhere. Set your terminal profile to launch `nu` if desired.

## Managed locations

The repository remains the source of truth. Setup creates junctions from application config locations to these directories:

- `%LOCALAPPDATA%\nvim` -> `nvim`
- `%APPDATA%\nushell` -> `nushell`
- `%USERPROFILE%\.config\wezterm` -> `wezterm`
- `%APPDATA%\yazi\config` -> `yazi`
- `%USERPROFILE%\.config\gh-dash` -> `gh-dash`
- `%USERPROFILE%\.config\spotify-player` -> `spotify-player`

Private operational data is intentionally not junctioned or committed:

- `%LOCALAPPDATA%\nu-api`
- `%LOCALAPPDATA%\nu-db`
- `%LOCALAPPDATA%\nu-observe`

Use `api collection init <name>` and `db init <name>` to create private configuration. See `doc/NU_API_COMMANDS.md` and `doc/NU_DB_COMMANDS.md` for the command references.

## Credentials

Keep credentials out of this repository. The API and database modules support environment-variable and interactive-prompt secret providers. OAuth access-token cache files are encrypted with Windows DPAPI for the current Windows user.

Postman imports redact conventionally sensitive environment values and auth fields into `NU_API_IMPORT_*` environment-variable references by default. Set those environment variables after importing. Use `api import postman-env --include-secrets` only when you explicitly accept storing imported values as plaintext in the private workspace.

## Validation

Run the local validation suite after changing configuration:

```powershell
.\scripts\validate.ps1
```

It parses the PowerShell and Nushell modules, verifies a local DPAPI round trip, checks database default-environment selection, and validates installed WezTerm and Neovim configurations.

## Updating and recovery

Pull changes and rerun `setup.ps1`; existing matching junctions and installed tools are left in place. To stop managing one application, remove only its junction and restore or create a real config directory at that location. Do not delete the repository or private workspaces unless you intend to remove their configuration and data.
