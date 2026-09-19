def value-or [value: any, fallback: string = "-"] {
  if $value == null {
    $fallback
  } else {
    let text = ($value | into string)

    if ($text | is-empty) {
      $fallback
    } else {
      $text
    }
  }
}

def label-value [labels: any, key: string] {
  if $labels == null {
    return null
  }

  let kind = ($labels | describe)

  if ($kind | str starts-with "record") {
    $labels | get -o $key
  } else {
    null
  }
}

def header [text: string] {
  print $"── ($text) ─────────────────────────────────────"
}

def main [container: string] {
  if ($container | str starts-with "__group__") {
    print "Compose project"
    print ""
    print "Select a container to see details."
    return
  }

  if $container == "__none__" or ($container | is-empty) {
    print "No container selected."
    return
  }

  let inspect_result = (
    ^podman container inspect $container
    | complete
  )

  if $inspect_result.exit_code != 0 {
    print $"Could not inspect container: ($container)"
    return
  }

  let info = try {
    $inspect_result.stdout
    | from json
    | first
  } catch {
    null
  }

  if $info == null {
    print $"Could not inspect container: ($container)"
    return
  }

  let name = (
    $info
    | get -o Name
    | default $container
    | into string
    | str trim --left --char "/"
  )

  let state = ($info | get -o State.Status | default "unknown")
  let image = ($info | get -o Config.Image)
  let labels = ($info | get -o Config.Labels)

  let project = (
    label-value $labels "com.docker.compose.project"
    | default (
        label-value $labels "io.podman.compose.project"
      )
  )

  let service = (
    label-value $labels "com.docker.compose.service"
    | default (
        label-value $labels "io.podman.compose.service"
      )
  )

  let compose_file = (
    label-value $labels "com.docker.compose.project.config_files"
  )

  let working_dir = (
    label-value $labels "com.docker.compose.project.working_dir"
  )

  print $"($name)"
  print $"($state | str uppercase)  •  (value-or $image)"
  print ""

  header "Compose"
  print $"Project    (value-or $project "Standalone")"
  print $"Service    (value-or $service)"
  print $"File       (value-or $compose_file)"
  print $"Directory  (value-or $working_dir)"
  print ""

  header "Resources"

  if $state == "running" {
    let stats_result = (
      ^podman stats --no-stream --format=json $container
      | complete
    )

    if $stats_result.exit_code == 0 {
      let stats = try {
        $stats_result.stdout
        | from json
        | first
      } catch {
        null
      }

      if $stats != null {
        print $"CPU        (value-or ($stats | get -o cpu_percent))"
        print $"Memory     (value-or ($stats | get -o mem_usage))"
        print $"Memory %   (value-or ($stats | get -o mem_percent))"
        print $"Network    (value-or ($stats | get -o netio))"
        print $"Block I/O  (value-or ($stats | get -o blocki))"
        print $"PIDs       (value-or ($stats | get -o pids))"
      } else {
        print "Stats unavailable."
      }
    } else {
      print "Stats unavailable."
    }
  } else {
    print "Container is not running."
  }

  print ""
  header "Ports"

  let ports = ($info | get -o NetworkSettings.Ports)

  if $ports == null {
    print "-"
  } else {
    print ($ports | table --expand)
  }

  print ""
  header "Recent logs"

  let logs = (
    ^podman logs --tail 20 $container
    | complete
  )

  if $logs.exit_code == 0 {
    let stdout = ($logs.stdout | str trim)
    let stderr = ($logs.stderr | str trim)

    if not ($stdout | is-empty) {
      print $stdout
    }

    if not ($stderr | is-empty) {
      print $stderr
    }

    if ($stdout | is-empty) and ($stderr | is-empty) {
      print "(no recent logs)"
    }
  } else {
    print "(logs unavailable for this container)"
  }
}
