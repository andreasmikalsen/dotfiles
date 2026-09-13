use ./helpers.nu *
use ./auth.nu [resolve-auth-headers]
use ./folder.nu [apply-folder-inheritance]

# Resolve a saved request name to its .nuon file.
def request-path [name: string] {
  let relative = if ($name | str ends-with ".nuon") {
    $name
  } else {
    $"($name).nuon"
  }

  collection-dir | path join "requests" $relative
}

# Run a dynamic pre/post hook in a child Nushell process.
def run-hook [
  hook: string
  request_file: string
  value: record
] {
  let hook_path = ($request_file | path dirname | path join $hook)

  if not ($hook_path | path exists) {
    error make { msg: $"Hook not found: ($hook_path)" }
  }

  let result = (
    $value
    | to json --raw
    | ^nu -n --stdin $hook_path
    | complete
  )

  if $result.exit_code != 0 {
    error make { msg: $"Hook failed: ($hook_path)\n($result.stderr)" }
  }

  let output = ($result.stdout | str trim)
  if ($output | is-empty) {
    error make { msg: $"Hook returned no data: ($hook_path)" }
  }

  try {
    $output | from json
  } catch {
    error make { msg: $"Hook did not return valid JSON: ($hook_path)" }
  }
}

# Build the final URL including optional query parameters.
def build-url [ctx: record, request: record] {
  let explicit_url = ($request | get -o url)
  let path = ($request | get -o path)

  let url = if $explicit_url != null and not (($explicit_url | into string) | is-empty) {
    $explicit_url
  } else {
    let base_url = ($ctx.variables | get -o base_url)
    if $base_url == null {
      error make { msg: "Request has no url and the environment has no base_url" }
    }

    if $path == null {
      $base_url
    } else {
      join-url $base_url $path
    }
  }

  let query = ($request | get -o query)
  if $query == null or (($query | columns | length) == 0) {
    return $url
  }

  let encoded = ($query | url build-query)
  let separator = if ($url | str contains "?") { "&" } else { "?" }
  $"($url)($separator)($encoded)"
}

# Execute a resolved request.
def perform-request [ctx: record, request: record] {
  let method = ($request | get -o method | default "GET" | str uppercase)
  let url = (build-url $ctx $request)
  let headers = ($request | get -o headers | default {})
  let auth_headers = (
    resolve-auth-headers
      ($request | get -o auth)
      $ctx.config
      $ctx.variables
  )
  let final_headers = ($headers | merge $auth_headers)
  let body = ($request | get -o body)
  let content_type = ($request | get -o content_type | default "application/json")

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
      error make { msg: $"Unsupported HTTP method: ($method)" }
    }
  }
}

# List saved requests. _folder.nuon metadata files are hidden from the list.
export def "api list" [] {
  let root = (collection-dir | path join "requests")

  if not ($root | path exists) {
    return []
  }

  let pattern = (
    $"($root)/**/*.nuon"
    | str replace --all '\\' '/'
    | into glob
  )

  glob $pattern
  | where {|path| ($path | path basename) != "_folder.nuon" }
  | each {|path|
      $path
      | path relative-to $root
      | str replace --all '\\' '/'
      | str replace --regex '\.nuon$' ''
    }
  | sort
}

# Show a saved request. By default this includes inherited folder settings.
# Use --raw to show only the request file itself.
export def "api show" [name: string, --raw] {
  let path = (request-path $name)

  if not ($path | path exists) {
    error make { msg: $"Request not found: ($name)" }
  }

  let request = (open $path)

  if $raw {
    $request
  } else {
    apply-folder-inheritance $path $request
  }
}

# Execute a saved request.
export def "api run" [name: string] {
  let path = (request-path $name)

  if not ($path | path exists) {
    error make { msg: $"Request not found: ($name)" }
  }

  let base_ctx = (context)
  let raw_request = (open $path)
  let inherited_request = (apply-folder-inheritance $path $raw_request)

  # Folder/request variables extend collection + environment variables.
  let request_variables = ($inherited_request | get -o variables | default {})
  let resolved_request_variables = (resolve-value $request_variables $base_ctx.variables)
  let variables = ($base_ctx.variables | merge $resolved_request_variables)
  mut ctx = ($base_ctx | upsert variables $variables)
  mut request = (resolve-value $inherited_request $variables)

  let hooks = ($request | get -o hooks | default {})
  let pre_hook = ($hooks | get -o pre)

  if $pre_hook != null {
    let pre_result = (run-hook $pre_hook $path {
      context: $ctx
      request: $request
    })

    let hook_ctx = ($pre_result | get -o context)
    let hook_request = ($pre_result | get -o request)

    if $hook_ctx != null {
      $ctx = $hook_ctx
    }

    if $hook_request != null {
      $request = $hook_request
    }
  }

  let response = (perform-request $ctx $request)
  let post_hook = ($hooks | get -o post)

  if $post_hook == null {
    $response
  } else {
    run-hook $post_hook $path {
      context: $ctx
      request: $request
      response: $response
    }
  }
}
