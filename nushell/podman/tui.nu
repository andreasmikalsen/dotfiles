use ./helpers.nu *
use ./commands.nu *

def state-icon [state: string] {
  match ($state | str lowercase) {
    "running" => "●"
    "paused" => "◐"
    "created" => "◌"
    "initialized" => "◌"
    "exited" => "○"
    "stopped" => "○"
    "stopping" => "◒"
    _ => "·"
  }
}

def container-view [] {
  containers
  | each {|container|
      let compose = (compose-meta $container)
      let name = (container-name $container)
      let service = if $compose.service == null {
        $name
      } else {
        $compose.service
      }

      {
        selector: $name
        id: (container-id $container)
        name: $name
        service: $service
        image: (container-image $container)
        state: (container-state $container)
        status: (container-status $container)
        project: $compose.project
        config_files: $compose.config_files
        group_key: $compose.group_key
      }
    }
  | sort-by group_key service name
}

def group-count [items: list<record>, group_key: string] {
  $items
  | where group_key == $group_key
  | length
}

def tui-rows [] {
  if not (machine-running) {
    return [
      ([
        "__none__"
        "empty"
        ""
        "·"
        "Podman machine is stopped"
        ""
        ""
        ""
      ] | str join (char tab))
    ]
  }

  let items = (container-view)

  if ($items | is-empty) {
    return [
      ([
        "__none__"
        "empty"
        ""
        "·"
        "No containers"
        ""
        ""
        ""
      ] | str join (char tab))
    ]
  }

  mut rows = []
  mut current_group = ""

  for item in $items {
    if $item.group_key != $current_group {
      $current_group = $item.group_key
      let count = (group-count $items $item.group_key)
      let noun = if $count == 1 { "container" } else { "containers" }

      let group_label = if $item.project == "Standalone" {
        $"Standalone  •  ($count) ($noun)"
      } else {
        $"($item.project) (compose)  •  ($count) ($noun)"
      }

      $rows = (
        $rows
        | append (
            [
              $"__group__:($item.group_key)"
              "group"
              $item.group_key
              ""
              $"━━ ($group_label)"
              ""
              ""
              ""
            ]
            | str join (char tab)
          )
      )
    }

    $rows = (
      $rows
      | append (
          [
            $item.selector
            "container"
            $item.group_key
            (state-icon $item.state)
            $"  ($item.service)"
            $item.state
            $item.status
            $item.image
          ]
          | str join (char tab)
        )
    )
  }

  $rows
}

def tui-header [] {
  let state = (machine-state)
  let items = (container-view)
  let running = (
    $items
    | where state == "running"
    | length
  )
  let total = ($items | length)
  let projects = (
    $items
    | where project != "Standalone"
    | get project
    | uniq
    | length
  )
  let current_file = (compose-file)

  let current_project = if $current_file == null {
    "none"
  } else {
    $"(project-name) • ($current_file | path basename)"
  }

  [
    $" PODMAN  ($state | str uppercase)     ($running)/($total) running     ($projects) compose projects"
    $" Current directory project: ($current_project)"
    ""
    " j/k select   h/l hide/show details   / search   Esc normal mode   q quit"
    " F5/F6/F7 machine start/stop/restart   Ctrl-U/Ctrl-D compose up/down"
    " Alt-S/Alt-X/Alt-R container start/stop/restart   Ctrl-R refresh"
  ]
  | str join (char newline)
}

def selected-container [line: any] {
  if $line == null {
    return null
  }

  let fields = ($line | split row (char tab))

  if ($fields | length) < 2 {
    return null
  }

  let selector = ($fields | get 0)
  let kind = ($fields | get 1)

  if $kind != "container" {
    null
  } else {
    $selector
  }
}

def preview-command [] {
  let preview_script = (
    $nu.default-config-dir
    | path join "podman" "preview.nu"
  )

  $"\"($nu.current-exe)\" --no-config-file \"($preview_script)\" \"{1}\""
}

def run-tui-once [] {
  let rows = (tui-rows)
  let header = (tui-header)
  let preview = (preview-command)

  let result = (
    $rows
    | str join (char newline)
    | ^fzf
        --delimiter (char tab)
        --with-nth "4.."
        --no-sort
        --layout reverse
        --border rounded
        --list-border rounded
        --list-label " Containers "
        --preview-border rounded
        --preview-label " Details "
        --info inline-right
        --no-input
        --prompt " search> "
        --header $header
        --expect "f5,f6,f7,ctrl-u,ctrl-d,ctrl-r,alt-s,alt-x,alt-r"
        --bind "j:down,k:up,h:hide-preview,l:show-preview,q:abort"
        --bind "/:show-input+enable-search+unbind(j,k,h,l,q,/)"
        --bind "esc:hide-input+disable-search+clear-query+rebind(j,k,h,l,q,/)"
        --preview $preview
        --preview-window "right,55%,wrap,border-left"
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
  let container = (selected-container $selection)

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
      if $container != null {
        pod container start $container
      }
    }

    "alt-x" => {
      if $container != null {
        pod container stop $container
      }
    }

    "alt-r" => {
      if $container != null {
        pod container restart $container
      }
    }

    "ctrl-r" => {
      # Redraw.
    }

    _ => {
      # Enter/unhandled key simply redraws.
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
