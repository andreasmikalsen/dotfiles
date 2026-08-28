use ./helpers.nu *
use ./auth.nu resolve-auth-headers

def request-path [name: string] {
  let filename = if ($name | str ends-with ".nuon") {
    $name
  } else {
    $"($name).nuon"
  }

  collection-dir
  | path join "requests" $filename
}

def run-hook [
  hook: string
  request_file: string
  value: record
] {
  let hook_path = (
    $request_file
    | path dirname
    | path join $hook
  )

  if not ($hook_path | path exists) {
    error make {
      msg: $"Hook not found: ($hook_path)"
    }
  }

  let result = (
    $value
    | to json --raw
    | ^nu -n --stdin $hook_path
    | complete
  )

  if $result.exit_code != 0 {
    error make {
      msg: $"Hook failed: ($hook_path)\n($result.stderr)"
    }
  }

  let output = ($result.stdout | str trim)

  if ($output | is-empty) {
    error make {
      msg: $"Hook returned no data: ($hook_path)"
    }
  }

  try {
    $output | from json
  } catch {
    error make {
      msg: $"Hook did not return valid JSON: ($hook_path)"
    }
  }
}

def build-url [request: record, variables: record] {
  let explicit_url = ($request | get -o url)

  let base_url = if $explicit_url != null {
    resolve-value $explicit_url $variables
  } else {
    let path = (
      resolve-value ($request | get path) $variables
    )

    let base = ($variables | get -o base_url)

    if $base == null {
      error make {
        msg: "Environment does not contain base_url"
      }
    }

    join-url $base $path
  }

  let query_raw = ($request | get -o query)

  if $query_raw == null {
    return $base_url
  }

  let query = (resolve-value $query_raw $variables)

  if (($query | columns | length) == 0) {
    return $base_url
  }

  $"($base_url)?($query | url build-query)"
}

def perform-request [
  request: record
  ctx: record
] {
  let variables = $ctx.variables
  let method = (($request | get method))
  let url = (build-url $request $variables)

  let raw_headers = ($request | get -o headers)

  let headers = if $raw_headers == null {
    {}
  } else {
    resolve-value $raw_headers $variables
  }

  let auth_ref = ($request | get -o auth)

  let auth_headers = (
    resolve-auth-headers
      $auth_ref
      $ctx.config
      $variables
  )

  let final_headers = ($headers | merge $auth_headers)

  let raw_body = ($request | get -o body)

  let body = if $raw_body == null {
    ""
  } else {
    resolve-value $raw_body $variables
  }

  let raw_content_type = ($request | get -o content_type)

  let content_type = if $raw_content_type == null {
    "application/json"
  } else {
    resolve-value $raw_content_type $variables
  }

  match $method {
    "GET" => (
      http get
        --headers $final_headers
        --full
        --allow-errors
        --pool
        $url
    )

    "POST" => (
      http post
        --headers $final_headers
        --content-type $content_type
        --full
        --allow-errors
        --pool
        $url
        $body
    )

    "PUT" => (
      http put
        --headers $final_headers
        --content-type $content_type
        --full
        --allow-errors
        --pool
        $url
        $body
    )

    "PATCH" => (
      http patch
        --headers $final_headers
        --content-type $content_type
        --full
        --allow-errors
        --pool
        $url
        $body
    )

    "DELETE" => (
      http delete
        --headers $final_headers
        --content-type $content_type
        --data $body
        --full
        --allow-errors
        --pool
        $url
    )

    _ => {
      error make {
        msg: $"Unsupported HTTP method: ($method)"
      }
    }
  }
}

export def "api list" [] {
  let root = (collection-dir | path join "requests")

  glob ($root | path join "**" "*.nuon")
  | each {|path|
      $path
      | path relative-to $root
      | str replace ".nuon" ""
    }
}

export def "api show" [name: string] {
  let path = (request-path $name)

  if not ($path | path exists) {
    error make {
      msg: $"Request not found: ($name)"
    }
  }

  open $path
}

export def "api run" [name: string] {
  let path = (request-path $name)

  if not ($path | path exists) {
    error make {
      msg: $"Request not found: ($name)"
    }
  }

  let ctx = (context)
  let raw_request = (open $path)

  let hooks = ($raw_request | get -o hooks)
  let pre_hook = if $hooks == null {
    null
  } else {
    $hooks | get -o pre
  }

  let post_hook = if $hooks == null {
    null
  } else {
    $hooks | get -o post
  }

  let initial = {
    context: $ctx
    request: $raw_request
  }

  let prepared = if $pre_hook == null {
    $initial
  } else {
    run-hook $pre_hook $path $initial
  }

  let response = (
    perform-request
      $prepared.request
      $prepared.context
  )

  let result = {
    context: $prepared.context
    request: $prepared.request
    response: $response
  }

  if $post_hook == null {
    $response
  } else {
    run-hook $post_hook $path $result
  }
}
