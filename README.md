# Setup configurations

## Neovim

### Install Neovim

Install [neovim](https://neovim.io/doc/install/)

### Install treesitter cli

`npm install -g tree-sitter-cli`

### Install zig

`winget install -e --id zig.zig`


Change the absolute path to zig-cc and zig-cxx in `nvim/lua/config.lua`


## Nushell

### Install nushell

`winget install nushell --scope machine`

- Setup default profile from terminal settings to use nushell.

### Install starship

`winget install nushell --scope machine`

## Install gh-dash

### Install gh cli

`winget install --id GitHub.cli --source winget`

### Install gh-dash extension

`gh extension install dlvhdr/gh-dash`

#### Install diffview
- Make sure you have Go: [go.dev](https://go.dev/doc/install)

```
git clone https://github.com/dlvhdr/diffnav.git
cd diffnav
go install .

winget install dandavison.delta
```
Install [Zellij](https://zellij.dev/)
## Setup junctions on windows

- Run `./setup.ps1`
