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
  if (machine-running) { return }
  ^podman machine start --quiet
}

export def "pod machine stop" [] {
  require-command podman
  if not (machine-running) { return }
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
        id: ($container | get -o ID)
        project: $compose.project
        service: $compose.service
        name: ($container | get -o Names)
        image: ($container | get -o Image)
        state: ($container | get -o State)
        status: ($container | get -o Status)
        ports: ($container | get -o Ports)
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

export def "pod compose up" [--build] {
  require-command podman
  let file = (require-compose-file)
  if not (machine-running) {
    error make { msg: "Podman machine is not running. Run: pod machine start" }
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
  if not (machine-running) { return }
  ^podman compose -f $file down
}

export def "pod compose restart" [] {
  require-command podman
  let file = (require-compose-file)
  if not (machine-running) {
    error make { msg: "Podman machine is not running. Run: pod machine start" }
  }
  ^podman compose -f $file restart
}

export def "pod compose ps" [] {
  require-command podman
  let file = (require-compose-file)
  if not (machine-running) { return }
  ^podman compose -f $file ps
}

export def "pod compose logs" [--tail: int = 100] {
  require-command podman
  let file = (require-compose-file)
  if not (machine-running) {
    error make { msg: "Podman machine is not running. Run: pod machine start" }
  }
  ^podman compose -f $file logs --tail $tail -f
}

export def "pod container start" [id: string] {
  require-command podman
  ^podman start $id
}

export def "pod container stop" [id: string] {
  require-command podman
  ^podman stop $id
}

export def "pod container restart" [id: string] {
  require-command podman
  ^podman restart $id
}

export def "pod container logs" [id: string, --tail: int = 100] {
  require-command podman
  ^podman logs --tail $tail -f $id
}

export def "pod container stats" [id: string] {
  require-command podman
  let result = (
    ^podman stats --no-stream --format=json $id
    | complete
  )
  if $result.exit_code != 0 { return null }
  try {
    $result.stdout | from json | first
  } catch {
    null
  }
}
