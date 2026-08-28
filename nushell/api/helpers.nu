export def api-home [] {
  if "NU_API_HOME" not-in $env {
    error make {
      msg: "NU_API_HOME is not configured"
    }
  }

  $env.NU_API_HOME | path expand
}

export def selected-collection [] {
  if "NU_API_COLLECTION" not-in $env {
    error make {
      msg: "No API collection selected. Run: api collection use <name>"
    }
  }

  $env.NU_API_COLLECTION
}

export def selected-environment [] {
  if "NU_API_ENV" not-in $env {
    error make {
      msg: "No API environment selected. Run: api env use <name>"
    }
  }

  $env.NU_API_ENV
}

export def collection-dir [] {
  api-home
  | path join "collections" (selected-collection)
}

export def collection-config [] {
  let path = (collection-dir | path join "collection.nuon")

  if not ($path | path exists) {
    error make {
      msg: $"Collection config not found: ($path)"
    }
  }

  open $path
}

export def environment-data [] {
  let path = (
    collection-dir
    | path join "environments" $"(selected-environment).nuon"
  )

  if not ($path | path exists) {
    error make {
      msg: $"Environment not found: ($path)"
    }
  }

  open $path
}

export def context [] {
  let config = (collection-config)
  let environment = (environment-data)

  let base_variables = (
    $config
    | get -o variables
  )

  let variables = if $base_variables == null {
    $environment
  } else {
    $base_variables | merge $environment
  }

  {
    collection: (selected-collection)
    environment_name: (selected-environment)
    collection_dir: (collection-dir)
    config: $config
    variables: $variables
  }
}

def render-string [value: string, variables: record] {
  $variables
  | transpose key value
  | reduce --fold $value {|row, result|
      let kind = ($row.value | describe)

      if $kind in ["string" "int" "float" "bool"] {
        let placeholder = (["{{" $row.key "}}"] | str join)

        $result
        | str replace --all $placeholder ($row.value | into string)
      } else {
        $result
      }
    }
}

export def render-template [value: any, variables: record] {
  let kind = ($value | describe)

  if $kind == "string" {
    render-string $value $variables
  } else if ($kind | str starts-with "record") {
    $value
    | transpose key value
    | reduce --fold {} {|row, result|
        $result
        | upsert $row.key (render-template $row.value $variables)
      }
  } else if ($kind | str starts-with "list") {
    $value | each {|item| render-template $item $variables }
  } else {
    $value
  }
}

def resolve-secret [value: record] {
  let secret = ($value | get secret)
  let provider = ($secret | get provider)

  match $provider {
    "env" => {
      let key = ($secret | get key)
      let value = ($env | get -o $key)

      if $value == null {
        error make {
          msg: $"Environment variable '($key)' is not set"
        }
      }

      $value
    }

    "prompt" => {
      let label = ($secret | get -o label)

      let prompt = if $label == null {
        "Secret"
      } else {
        $label
      }

      input --suppress-output $"($prompt): "
    }

    _ => {
      error make {
        msg: $"Unknown secret provider: ($provider)"
      }
    }
  }
}

export def resolve-value [value: any, variables: record] {
  let kind = ($value | describe)

  if ($kind | str starts-with "record") {
    let columns = ($value | columns)

    if (($columns | length) == 1 and "secret" in $columns) {
      resolve-secret $value
    } else {
      $value
      | transpose key value
      | reduce --fold {} {|row, result|
          $result
          | upsert $row.key (resolve-value $row.value $variables)
        }
    }
  } else if ($kind | str starts-with "list") {
    $value | each {|item| resolve-value $item $variables }
  } else if $kind == "string" {
    render-string $value $variables
  } else {
    $value
  }
}

export def join-url [base: string, path: string] {
  let left = ($base | str trim --right --char "/")
  let right = ($path | str trim --left --char "/")

  $"($left)/($right)"
}
