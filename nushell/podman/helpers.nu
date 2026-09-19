export def require-command [name: string] {
  if (which $name | is-empty) {
    error make { msg: $"Required command not found: ($name)" }
  }
}

export def compose-file [] {
  mut dir = $env.PWD
  let names = [
    "docker-compose.yml"
    "docker-compose.yaml"
    "compose.yml"
    "compose.yaml"
  ]

  loop {
    for name in $names {
      let candidate = ($dir | path join $name)

      if ($candidate | path exists) {
        return $candidate
      }
    }

    let parent = ($dir | path dirname)

    if $parent == $dir {
      break
    }

    $dir = $parent
  }

  null
}

export def machine-info [] {
  require-command podman

  let result = (
    ^podman machine inspect
    | complete
  )

  if $result.exit_code != 0 {
    return null
  }

  try {
    $result.stdout
    | from json
    | first
  } catch {
    null
  }
}

export def machine-state [] {
  let info = (machine-info)

  if $info == null {
    "not-created"
  } else {
    $info.State
    | default "unknown"
    | into string
    | str lowercase
  }
}

export def machine-running [] {
  (machine-state) == "running"
}

export def containers [] {
  require-command podman

  if not (machine-running) {
    return []
  }

  let result = (
    ^podman ps -a --format json
    | complete
  )

  if $result.exit_code != 0 {
    return []
  }

  try {
    $result.stdout | from json
  } catch {
    []
  }
}

export def label-value [container: record, key: string] {
  let labels = ($container | get -o Labels)

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

export def compose-meta [container: record] {
  let project = (
    label-value $container "com.docker.compose.project"
    | default (
        label-value $container "io.podman.compose.project"
      )
  )

  let service = (
    label-value $container "com.docker.compose.service"
    | default (
        label-value $container "io.podman.compose.service"
      )
  )

  let working_dir = (
    label-value $container "com.docker.compose.project.working_dir"
  )

  let config_files = (
    label-value $container "com.docker.compose.project.config_files"
  )

  let group_name = if $project == null {
    "Standalone"
  } else {
    $project
  }

  let config_display = if $config_files == null {
    if $project == null { "No Compose file" } else { "Compose" }
  } else {
    $config_files
  }

  let group_key = if $project == null {
    "zzzz|standalone"
  } else {
    $"($working_dir | default '')|($config_files | default '')|($project)"
  }

  {
    project: $group_name
    service: $service
    working_dir: $working_dir
    config_files: $config_files
    config_display: $config_display
    group_key: $group_key
  }
}

export def project-name [] {
  let file = (compose-file)

  if $file == null {
    null
  } else {
    $file | path dirname | path basename
  }
}

export def require-compose-file [] {
  let file = (compose-file)

  if $file == null {
    error make {
      msg: "No compose file found in this directory or any parent directory"
    }
  }

  $file
}
