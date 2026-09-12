use ./helpers.nu *

export def "api collections" [] {
  let root = (api-home | path join "collections")

  if not ($root | path exists) {
    return []
  }

  ls $root
  | where type == dir
  | get name
  | each {|path| $path | path basename }
}

export def --env "api collection use" [name: string] {
  let root = (api-home | path join "collections" $name)

  if not ($root | path exists) {
    error make {
      msg: $"Collection not found: ($name)"
    }
  }

  $env.NU_API_COLLECTION = $name

  let config_path = ($root | path join "collection.nuon")

  if ($config_path | path exists) {
    let config = (open $config_path)
    let default_environment = ($config | get -o default_environment)

    if $default_environment != null {
      $env.NU_API_ENV = $default_environment
    }
  }

  api status
}

export def "api env list" [] {
  let root = (collection-dir | path join "environments")

  if not ($root | path exists) {
    return []
  }

  let pattern = (
    $"($root)/**/*.nuon"
    | str replace --all '\' '/'
    | into glob
  )

  glob $pattern
  | each {|path|
      $path
      | path parse
      | get stem
    }
}

export def --env "api env use" [name: string] {
  let path = (
    collection-dir
    | path join "environments" $"($name).nuon"
  )

  if not ($path | path exists) {
    error make {
      msg: $"Environment not found: ($name)"
    }
  }

  $env.NU_API_ENV = $name

  api status
}

export def "api status" [] {
  {
    home: (api-home)
    collection: (
      if "NU_API_COLLECTION" in $env {
        $env.NU_API_COLLECTION
      } else {
        null
      }
    )
    environment: (
      if "NU_API_ENV" in $env {
        $env.NU_API_ENV
      } else {
        null
      }
    )
  }
}

export def "api collection init" [name: string] {
  let root = (api-home | path join "collections" $name)

  if ($root | path exists) {
    error make {
      msg: $"Collection already exists: ($name)"
    }
  }

  mkdir $root
  mkdir ($root | path join "environments")
  mkdir ($root | path join "requests")

  {
    name: $name
    default_environment: "local"

    variables: {}

    auth: {
      default: {
        type: "oauth2_client_credentials"

        token_url: "{{token_url}}"

        client_id: {
          secret: {
            provider: "env"
            key: "API_CLIENT_ID"
          }
        }

        client_secret: {
          secret: {
            provider: "prompt"
            label: "OAuth client secret"
          }
        }

        scope: ""
      }
    }
  }
  | to nuon --pretty
  | save ($root | path join "collection.nuon")

  {
    base_url: "http://localhost:8080"
    token_url: "http://localhost:8080/oauth/token"
  }
  | to nuon --pretty
  | save ($root | path join "environments" "local.nuon")

  {
    name: "Health"
    method: "GET"
    path: "/health"
    auth: null
    headers: {
      Accept: "application/json"
    }
  }
  | to nuon --pretty
  | save ($root | path join "requests" "health.nuon")

  print $"Created collection: ($root)"
}
