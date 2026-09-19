use ./helpers.nu *

export def "pod machine status" [] {
  let info = (machine-info)

  if $info == null {
    return {
      name: null
      state: "not-created"
    }
  }

  {
    name: ($info | get -o Name)
    state: ($info | get -o State)
    rootful: ($info | get -o Rootful)
    last_up: ($info | get -o LastUp)
    resources: ($info | get -o Resources)
  }
}

export def "pod machine start" [] {
  require-command podman

  if (machine-running) {
    return
  }

  ^podman machine start --quiet
}

export def "pod machine stop" [] {
  require-command podman

  if not (machine-running) {
    return
  }

  ^podman machine stop
}

export def "pod machine restart" [] {
  require-command podman
  ^podman machine restart --quiet
}

export def "pod ps" [] {
  containers
  | each {|container|
      let compose = (compose-meta $container)

      {
        id: (container-id $container)
        project: $compose.project
        service: $compose.service
        name: (container-name $container)
        image: (container-image $container)
        state: (container-state $container)
        status: (container-status $container)
      }
    }
}

export def "pod status" [] {
  let file = (compose-file)

  {
    machine: (machine-state)
    compose_file: $file
    project: (project-name)
    containers: (containers | length)
  }
}

export def "pod compose up" [
  --build
] {
  require-command podman
  let file = (require-compose-file)

  if not (machine-running) {
    error make {
      msg: "Podman machine is not running. Run: pod machine start"
    }
  }

  if $build {
    ^podman compose -f $file up -d --build
  } else {
    ^podman compose -f $file up -d
  }
}

export def "pod compose down" [] {
  require-command podman
  let file = (require-compose-file)

  if not (machine-running) {
    return
  }

  ^podman compose -f $file down
}

export def "pod compose restart" [] {
  require-command podman
  let file = (require-compose-file)

  if not (machine-running) {
    error make {
      msg: "Podman machine is not running. Run: pod machine start"
    }
  }

  ^podman compose -f $file restart
}

export def "pod compose ps" [] {
  require-command podman
  let file = (require-compose-file)

  if not (machine-running) {
    return
  }

  ^podman compose -f $file ps
}

export def "pod compose logs" [
  --tail: int = 100
] {
  require-command podman
  let file = (require-compose-file)

  if not (machine-running) {
    error make {
      msg: "Podman machine is not running. Run: pod machine start"
    }
  }

  ^podman compose -f $file logs --tail $tail -f
}

export def "pod container start" [container: string] {
  require-command podman
  ^podman start $container
}

export def "pod container stop" [container: string] {
  require-command podman
  ^podman stop $container
}

export def "pod container restart" [container: string] {
  require-command podman
  ^podman restart $container
}

export def "pod container logs" [
  container: string
  --tail: int = 100
] {
  require-command podman
  ^podman logs --tail $tail $container
}

export def "pod container stats" [container: string] {
  require-command podman

  let result = (
    ^podman stats --no-stream --format=json $container
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
