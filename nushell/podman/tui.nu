use ./helpers.nu *
use ./commands.nu *

def display-name [value: any] {
  let kind = ($value | describe)

  if ($kind | str starts-with "list") {
    $value | each {|item| $item | into string } | str join ","
  } else if $value == null {
    ""
  } else {
    $value | into string
  }
}

def state-icon [state: string] {
  match ($state | str lowercase) {
    "running" => "●"
    "paused" => "◐"
    "created" => "◌"
    "exited" => "○"
    "stopped" => "○"
    _ => "·"
  }
}

def tui-rows [] {
  if not (machine-running) {
    return [
      ([
        "__none__"
        "·"
        "(Podman machine is stopped)"
        ""
        ""
        ""
      ] | str join (char tab))
    ]
  }

  let items = (containers)

  if ($items | is-empty) {
    return [
      ([
        "__none__"
        "·"
        "(no containers)"
        ""
        ""
        ""
      ] | str join (char tab))
    ]
  }

  $items
  | sort-by Names
  | each {|container|
      let id = ($container | get -o ID | default "")
      let name = (display-name ($container | get -o Names))
      let image = (display-name ($container | get -o Image))
      let state = (
        $container
        | get -o State
        | default "unknown"
        | into string
        | str lowercase
      )
      let status = (display-name ($container | get -o Status))

      [
        $id
        (state-icon $state)
        $name
        $state
        $status
        $image
      ]
      | str join (char tab)
    }
}

def tui-header [] {
  let state = (machine-state)
  let file = (compose-file)
  let project = (project-name)
  let project_text = if $file == null {
    "none"
  } else {
    $"($project)  [($file)]"
  }

  [
    $"Podman machine: ($state)"
    $"Compose project: ($project_text)"
    ""
    "F5 start machine   F6 stop machine   F7 restart machine"
    "Ctrl-U compose up  Ctrl-D compose down"
    "Alt-S start ctr    Alt-X stop ctr    Alt-R restart ctr"
    "Ctrl-R refresh     Ctrl-/ toggle logs preview     Esc quit"
  ]
  | str join (char newline)
}

def selected-id [line: any] {
  if $line == null {
    return null
  }

  let id = (
    $line
    | split row (char tab)
    | first
  )

  if $id == "__none__" {
    null
  } else {
    $id
  }
}

def run-tui-once [] {
  let rows = (tui-rows)
  let header = (tui-header)

  let result = (
    $rows
    | str join (char newline)
    | ^fzf
        --delimiter (char tab)
        --with-nth "2.."
        --layout reverse
        --border rounded
        --info inline
        --prompt "containers> "
        --header $header
        --expect "f5,f6,f7,ctrl-u,ctrl-d,ctrl-r,alt-s,alt-x,alt-r"
        --bind "ctrl-/:toggle-preview"
        --preview "podman logs --tail 80 {1}"
        --preview-window "right,50%,wrap"
    | complete
  )

  if $result.exit_code != 0 {
    return { quit: true }
  }

  let lines = ($result.stdout | lines)

  if ($lines | is-empty) {
    return { quit: true }
  }

  let key = ($lines | first)
  let selection = ($lines | get -o 1)
  let id = (selected-id $selection)

  match $key {
    "f5" => {
      pod machine start
    }

    "f6" => {
      pod machine stop
    }

    "f7" => {
      pod machine restart
    }

    "ctrl-u" => {
      if not (machine-running) {
        pod machine start
      }

      pod compose up
    }

    "ctrl-d" => {
      pod compose down
    }

    "alt-s" => {
      if $id != null {
        pod container start $id
      }
    }

    "alt-x" => {
      if $id != null {
        pod container stop $id
      }
    }

    "alt-r" => {
      if $id != null {
        pod container restart $id
      }
    }

    "ctrl-r" => {
      # Refresh only.
    }

    _ => {
      # Enter or an unhandled key simply redraws.
    }
  }

  { quit: false }
}

export def "pod tui" [] {
  require-command podman
  require-command fzf

  loop {
    let result = (run-tui-once)

    if $result.quit {
      break
    }
  }
}
