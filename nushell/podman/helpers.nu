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
