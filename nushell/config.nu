$env.config.buffer_editor = "nvim"
$env.STARSHIP_CONFIG = ($nu.default-config-dir | path join ".." "starship" "starship.toml" | path expand)
mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")
alias gd  = gh dash
alias dot = cd ~/dotfiles/
source ./nu_scripts/git-completion.nu
