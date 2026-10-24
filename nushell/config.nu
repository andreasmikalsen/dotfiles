# Import api mod
use ($nu.default-config-dir | path join "api" "mod.nu") *
use ($nu.default-config-dir | path join "api" "help.nu") api
use ($nu.default-config-dir | path join "api" "import-postman.nu") *
use ($nu.default-config-dir | path join "db" "mod.nu") *
use ($nu.default-config-dir | path join "db" "help.nu") db
use ($nu.default-config-dir | path join "podman" "mod.nu") *
use ($nu.default-config-dir | path join "podman" "help.nu") pod
use ($nu.default-config-dir | path join "observe" "mod.nu") *

$env.config.buffer_editor = "nvim"
$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.config.history.file_format = "sqlite"

# Workaround for WezTerm/Nushell rendering issue
$env.config.shell_integration.osc133 = false

if "DOTFILES" in $env {
  let starship_config = ($env.DOTFILES | path join "starship" "starship.toml")
  if ($starship_config | path exists) {
    $env.STARSHIP_CONFIG = $starship_config
  }
}

# Nushell loads vendor autoload files automatically. Generate them only when absent
# so starting a shell never depends on rewriting files or optional commands.
let vendor_autoload = ($nu.data-dir | path join "vendor/autoload")
mkdir $vendor_autoload

let starship_autoload = ($vendor_autoload | path join "starship.nu")
if (which starship | is-not-empty) and not ($starship_autoload | path exists) {
  starship init nu | save -f $starship_autoload
}

let zoxide_autoload = ($vendor_autoload | path join "zoxide.nu")
if (which zoxide | is-not-empty) and not ($zoxide_autoload | path exists) {
  zoxide init nushell | save -f $zoxide_autoload
}

alias pui     = pod tui
alias nudb    = cd $env.NU_DB_HOME
alias nuapi   = cd $env.NU_API_HOME
alias gd      = gh dash
alias dot     = cd $env.DOTFILES
alias github  = cd ~/Documents/GitHub
alias lg      = lazygit
alias l       = eza --icons=auto --group-directories-first
alias ll      = eza -la --icons=auto --group-directories-first
alias nuobs   = cd $env.NU_OBSERVE_HOME
alias sfy     = spotify_player
alias spotify = spotify_player
alias todo    = nvim ~/todo

source ($nu.default-config-dir | path join "nu_scripts" "git-completion.nu")

# Nushell wrapper for Yazi
def --env y [...args] {
  let tmp = (mktemp -t "yazi-cwd.XXXXXX")

  try {
    ^yazi ...$args --cwd-file $tmp

    if ($tmp | path exists) {
      let cwd = (open $tmp | str trim)

      if not ($cwd | is-empty) and $cwd != $env.PWD and ($cwd | path exists) {
        cd $cwd
      }
    }
  } finally {
    rm -f $tmp
  }
}
