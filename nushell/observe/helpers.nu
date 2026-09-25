export def observe-home [] {
  if "NU_OBSERVE_HOME" not-in $env {
    error make { msg: "NU_OBSERVE_HOME is not configured" }
  }
  $env.NU_OBSERVE_HOME | path expand
}

export def selected-environment [] {
  if "NU_OBSERVE_ENV" not-in $env {
    error make { msg: "No observe environment selected. Run: obs env use <name>" }
  }
  $env.NU_OBSERVE_ENV
}

export def environment-path [name?: string] {
  let environment = if $name == null { selected-environment } else { $name }
  observe-home | path join "environments" $"($environment).nuon"
}

export def environment-data [name?: string] {
  let path = (environment-path $name)
  if not ($path | path exists) {
    error make { msg: $"Observe environment not found: ($path)" }
  }
  open $path
}

export def dashboard-data [name: string] {
  let path = (observe-home | path join "dashboards" $"($name).nuon")
  if not ($path | path exists) {
    error make { msg: $"Dashboard not found: ($name)" }
  }
  open $path
}

export def sql-file [name: string] {
  let path = (observe-home | path join "queries" $name)
  if not ($path | path exists) {
    error make { msg: $"SQL query file not found: ($path)" }
  }
  open --raw $path
}

export def auth-headers [config: record] {
  let auth = ($config | get -o auth)
  if $auth == null { return {} }
  let kind = ($auth | get -o type | default "none")
  match $kind {
    "none" => {},
    "bearer_env" => {
      let variable = ($auth | get variable)
      let token = ($env | get -o $variable)
      if $token == null {
        error make { msg: $"Environment variable '($variable)' is not set" }
      }
      { Authorization: $"Bearer ($token)" }
    },
    _ => { error make { msg: $"Unsupported observe auth type: ($kind)" } }
  }
}
