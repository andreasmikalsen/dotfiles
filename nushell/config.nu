# Import api mod
use ($nu.default-config-dir | path join "api" "mod.nu") *
use ($nu.default-config-dir | path join "api" "help.nu") api

$env.config.buffer_editor = "nvim"
$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.config.history.file_format = "sqlite"

# Workaround for WezTerm/Nushell rendering issue
$env.config.shell_integration.osc133 = false

$env.STARSHIP_CONFIG = ($env.DOTFILES | path join "starship" "starship.toml")

mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")
zoxide init nushell | save -f ($nu.data-dir | path join "vendor/autoload/zoxide.nu")

alias nuapi = cd $env.NU_API_HOME
alias gd  = gh dash
alias dot = cd $env.DOTFILES
alias github = cd ~/Documents/GitHub
alias lg = lazygit
alias l = eza --icons=auto --group-directories-first
alias ll = eza -la --icons=auto --group-directories-first

source ($nu.default-config-dir | path join "nu_scripts" "git-completion.nu")
