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
      let names = (display-name ($container | get -o Names))
      let service = if $compose.service == null { $names } else { $compose.service }
      {
        id: ($container | get -o ID | default "")
        name: $names
        service: $service
        image: (display-name ($container | get -o Image))
        state: ($container | get -o State | default "unknown" | into string | str lowercase)
        status: (display-name ($container | get -o Status))
        project: $compose.project
        config: $compose.config_display
        group_key: $compose.group_key
      }
    }
  | sort-by group_key service name
}

def tui-rows [] {
  if not (machine-running) {
    return [(["__none__" "empty" "" "·" "Podman machine is stopped" "" "" ""] | str join (char tab))]
  }

  let items = (container-view)
  if ($items | is-empty) {
    return [(["__none__" "empty" "" "·" "No containers" "" "" ""] | str join (char tab))]
  }

  mut rows = []
  mut current_group = ""

  for item in $items {
    if $item.group_key != $current_group {
      $current_group = $item.group_key
      let group_label = if $item.project == "Standalone" {
        "Standalone containers"
      } else {
        $"($item.project)  •  ($item.config)"
      }

      $rows = ($rows | append ([
        $"__group__:($item.group_key)"
        "group"
        $item.group_key
        ""
        $"━━ ($group_label)"
        ""
        ""
        ""
      ] | str join (char tab)))
    }

    $rows = ($rows | append ([
      $item.id
      "container"
      $item.group_key
      (state-icon $item.state)
      $"  ($item.service)"
      $item.state
      $item.status
      $item.image
    ] | str join (char tab)))
  }

  $rows
}

def tui-header [] {
  let state = (machine-state)
  let items = (container-view)
  let running = ($items | where state == "running" | length)
  let total = ($items | length)
  let projects = ($items | where project != "Standalone" | get project | uniq | length)
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
  ] | str join (char newline)
}

def selected-id [line: any] {
  if $line == null { return null }
  let fields = ($line | split row (char tab))
  if ($fields | length) < 2 { return null }
  let id = ($fields | get 0)
  let kind = ($fields | get 1)
  if $kind != "container" { null } else { $id }
}

def preview-command [] {
  let preview_script = ($nu.default-config-dir | path join "podman" "preview.nu")
  $"\"($nu.current-exe)\" --no-config-file \"($preview_script)\" {1}"
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

  if $result.exit_code != 0 { return { quit: true } }
  let lines = ($result.stdout | lines)
  if ($lines | is-empty) { return { quit: true } }

  let key = ($lines | first)
  let selection = ($lines | get -o 1)
  let id = (selected-id $selection)

  match $key {
    "f5" => { pod machine start }
    "f6" => { pod machine stop }
    "f7" => { pod machine restart }
    "ctrl-u" => {
      if not (machine-running) { pod machine start }
      pod compose up
    }
    "ctrl-d" => { pod compose down }
    "alt-s" => { if $id != null { pod container start $id } }
    "alt-x" => { if $id != null { pod container stop $id } }
    "alt-r" => { if $id != null { pod container restart $id } }
    "ctrl-r" => { }
    _ => { }
  }

  { quit: false }
}

export def "pod tui" [] {
  require-command podman
  require-command fzf
  loop {
    let result = (run-tui-once)
    if $result.quit { break }
  }
}
