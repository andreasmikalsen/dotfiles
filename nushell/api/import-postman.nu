use ./helpers.nu [api-home selected-collection]

# Convert a name to a filesystem-safe request/folder name.
def slug [name: any] {
  let text = if $name == null { "unnamed" } else { $name | into string }
  let result = ($text | str kebab-case | str replace --all "/" "-" | str replace --all "\\" "-")

  if ($result | is-empty) { "unnamed" } else { $result }
}

# Return true when a record actually contains a field.
def has-field [value: any, field: string] {
  let kind = ($value | describe)
  if not ($kind | str starts-with "record") {
    return false
  }

  $field in ($value | columns)
}

# Convert Postman's [{key,value,...}] representation to a Nushell record.
def kv-list-to-record [items: any] {
  if $items == null {
    return {}
  }

  $items
  | where {|item| ($item | get -o disabled) != true }
  | reduce --fold {} {|item, result|
      let key = ($item | get -o key)
      if $key == null or (($key | into string | str trim) | is-empty) {
        $result
      } else {
        let value = ($item | get -o value)
        $result | upsert ($key | into string) (if $value == null { "" } else { $value })
      }
    }
}

# Convert Postman collection/environment variables to a Nushell record.
def variables-to-record [items: any] {
  if $items == null {
    return {}
  }

  $items
  | where {|item| ($item | get -o disabled) != true }
  | reduce --fold {} {|item, result|
      let key = ($item | get -o key)
      if $key == null or (($key | into string | str trim) | is-empty) {
        $result
      } else {
        let value = ($item | get -o value)
        $result | upsert ($key | into string) (if $value == null { "" } else { $value })
      }
    }
}

# Convert Postman's auth parameter list into a record keyed by auth field name.
def auth-values [auth: any, field: string] {
  let values = ($auth | get -o $field)
  kv-list-to-record $values
}

# Convert a Postman auth object to a nu-api inline auth record.
# Returns { value, warning }.
def convert-auth [auth: any] {
  if $auth == null {
    return { value: null warning: null }
  }

  let auth_type = ($auth | get -o type)

  match $auth_type {
    null => { value: null warning: null }

    "noauth" => { value: null warning: null }

    "basic" => {
      let values = (auth-values $auth "basic")
      {
        value: {
          type: "basic"
          username: ($values | get -o username)
          password: ($values | get -o password)
        }
        warning: null
      }
    }

    "bearer" => {
      let values = (auth-values $auth "bearer")
      {
        value: {
          type: "bearer"
          token: ($values | get -o token)
        }
        warning: null
      }
    }

    "oauth2" => {
      let values = (auth-values $auth "oauth2")
      let grant_type = (
        $values
        | get -o grant_type
        | default ($values | get -o grantType)
      )
      let token_url = (
        $values
        | get -o accessTokenUrl
        | default ($values | get -o token_url)
        | default ($values | get -o tokenUrl)
      )
      let client_id = (
        $values
        | get -o clientId
        | default ($values | get -o client_id)
      )
      let client_secret = (
        $values
        | get -o clientSecret
        | default ($values | get -o client_secret)
      )
      let scope = ($values | get -o scope | default "")
      let access_token = (
        $values
        | get -o accessToken
        | default ($values | get -o access_token)
      )

      if (($grant_type == "client_credentials") or (($token_url != null) and ($client_id != null) and ($client_secret != null))) {
        {
          value: {
            type: "oauth2_client_credentials"
            token_url: $token_url
            client_id: $client_id
            client_secret: $client_secret
            scope: $scope
          }
          warning: null
        }
      } else if $access_token != null {
        {
          value: {
            type: "bearer"
            token: $access_token
          }
          warning: "OAuth2 auth was imported as a static bearer token because it was not client_credentials."
        }
      } else {
        {
          value: null
          warning: "Unsupported Postman OAuth2 configuration. Add auth manually to the generated request."
        }
      }
    }

    _ => {
      {
        value: null
        warning: $"Unsupported Postman auth type: ($auth_type)"
      }
    }
  }
}

# Collect Postman JavaScript event scripts of one type.
def event-scripts [events: any, listen: string, source: string] {
  if $events == null {
    return []
  }

  $events
  | where {|event| ($event | get -o listen) == $listen }
  | each {|event|
      let exec = ($event | get -o script.exec)
      let text = if $exec == null {
        ""
      } else if (($exec | describe) | str starts-with "list") {
        $exec | str join (char newline)
      } else {
        $exec | into string
      }

      {
        source: $source
        script: $text
      }
    }
}

# Convert a Postman URL to { url, query }.
def convert-url [value: any] {
  if $value == null {
    return { url: "" query: {} }
  }

  if ($value | describe) == "string" {
    return { url: $value query: {} }
  }

  let raw = ($value | get -o raw)
  let query_items = ($value | get -o query)
  let query = (kv-list-to-record $query_items)

  let clean_url = if $raw == null {
    ""
  } else if (($query | columns | length) > 0) {
    $raw | split row "?" | first
  } else {
    $raw
  }

  {
    url: $clean_url
    query: $query
  }
}

# Convert a Postman body to fields understood by nu-api.
# Returns { body, content_type, warning }.
def convert-body [body: any] {
  if $body == null {
    return { body: null content_type: null warning: null }
  }

  let mode = ($body | get -o mode)

  match $mode {
    null => { body: null content_type: null warning: null }

    "raw" => {
      let raw = ($body | get -o raw | default "")
      let language = ($body | get -o options.raw.language)

      if $language == "json" {
        let parsed = (try { $raw | from json } catch { null })
        if $parsed == null and not ($raw | str trim | is-empty) {
          {
            body: $raw
            content_type: "application/json"
            warning: "Raw body was marked as JSON but could not be parsed; it was kept as a string."
          }
        } else {
          {
            body: $parsed
            content_type: "application/json"
            warning: null
          }
        }
      } else {
        {
          body: $raw
          content_type: null
          warning: null
        }
      }
    }

    "urlencoded" => {
      {
        body: (kv-list-to-record ($body | get -o urlencoded))
        content_type: "application/x-www-form-urlencoded"
        warning: null
      }
    }

    "formdata" => {
      let entries = ($body | get -o formdata | default [])
      let file_entries = ($entries | where {|entry| ($entry | get -o type) == "file" })
      let text_entries = ($entries | where {|entry| (($entry | get -o type) | default "text") != "file" })

      {
        body: (kv-list-to-record $text_entries)
        content_type: "multipart/form-data"
        warning: (if ($file_entries | length) > 0 {
          "Multipart text fields were imported, but Postman file fields require manual conversion to Nushell open --raw expressions."
        } else { null })
      }
    }

    "graphql" => {
      let graphql = ($body | get -o graphql | default {})
      let query = ($graphql | get -o query | default "")
      let variables_raw = ($graphql | get -o variables | default "{}")
      let variables = (try { $variables_raw | from json } catch { $variables_raw })

      {
        body: {
          query: $query
          variables: $variables
        }
        content_type: "application/json"
        warning: null
      }
    }

    _ => {
      {
        body: null
        content_type: null
        warning: $"Unsupported Postman body mode: ($mode)"
      }
    }
  }
}

# Render one or more Postman scripts as commented source in a Nushell hook stub.
def script-comments [scripts: list] {
  $scripts
  | each {|entry|
      let source = ($entry | get source)
      let script = ($entry | get script)
      let commented = (
        $script
        | lines
        | each {|line| $"# ($line)" }
        | str join (char newline)
      )

      $"# ---- Postman: ($source) ----\n($commented)"
    }
  | str join "\n#\n"
}

# Save a no-op nu-api pre hook containing the original Postman JavaScript as comments.
def save-pre-hook [path: string, scripts: list] {
  let comments = (script-comments $scripts)
  let content = $"# Imported Postman pre-request script(s).\n# TODO: translate the JavaScript below to Nushell.\n# Until then this hook leaves the request unchanged.\n#\n($comments)\n\ndef main [] {\n  let state = \($in | from json\)\n  $state | to json --raw\n}\n"
  $content | save --force $path
}

# Save a transparent nu-api post hook containing the original Postman JavaScript as comments.
def save-post-hook [path: string, scripts: list] {
  let comments = (script-comments $scripts)
  let content = $"# Imported Postman test/post-response script(s).\n# TODO: translate the JavaScript below to Nushell.\n# Until then this hook returns the normal HTTP response unchanged.\n#\n($comments)\n\ndef main [] {\n  let state = \($in | from json\)\n  $state.response | to json --raw\n}\n"
  $content | save --force $path
}

# Import a single request and return counters/warnings.
def import-request [
  item: record
  target_dir: string
  inherited_auth: any
  inherited_pre: list
  inherited_post: list
] {
  let name = ($item | get -o name | default "Unnamed request")
  let request = ($item | get request)
  let file_name = $"(slug $name).nuon"
  let request_path = ($target_dir | path join $file_name)

  let own_auth = if (has-field $request "auth") { $request.auth } else { $inherited_auth }
  let auth_result = (convert-auth $own_auth)
  let url_result = (convert-url ($request | get -o url))
  let body_result = (convert-body ($request | get -o body))

  let headers = (kv-list-to-record ($request | get -o header))
  let method = ($request | get -o method | default "GET" | str uppercase)

  let local_pre = (event-scripts ($item | get -o event) "prerequest" $"request: ($name)")
  let local_post = (event-scripts ($item | get -o event) "test" $"request: ($name)")
  let pre_scripts = ($inherited_pre ++ $local_pre)
  let post_scripts = ($inherited_post ++ $local_post)

  mut output = {
    name: $name
    method: $method
    url: $url_result.url
    auth: $auth_result.value
  }

  if (($url_result.query | columns | length) > 0) {
    $output = ($output | upsert query $url_result.query)
  }

  if (($headers | columns | length) > 0) {
    $output = ($output | upsert headers $headers)
  }

  if $body_result.content_type != null {
    $output = ($output | upsert content_type $body_result.content_type)
  }

  if $body_result.body != null {
    $output = ($output | upsert body $body_result.body)
  }

  mut hooks = {}
  mut hook_count = 0

  if ($pre_scripts | length) > 0 {
    let hook_name = $"(slug $name).pre.nu"
    save-pre-hook ($target_dir | path join $hook_name) $pre_scripts
    $hooks = ($hooks | upsert pre $hook_name)
    $hook_count += 1
  }

  if ($post_scripts | length) > 0 {
    let hook_name = $"(slug $name).post.nu"
    save-post-hook ($target_dir | path join $hook_name) $post_scripts
    $hooks = ($hooks | upsert post $hook_name)
    $hook_count += 1
  }

  if (($hooks | columns | length) > 0) {
    $output = ($output | upsert hooks $hooks)
  }

  $output | to nuon --pretty | save --force $request_path

  mut warnings = []
  if $auth_result.warning != null {
    $warnings = ($warnings | append $"($name): ($auth_result.warning)")
  }
  if $body_result.warning != null {
    $warnings = ($warnings | append $"($name): ($body_result.warning)")
  }
  if ($url_result.url | is-empty) {
    $warnings = ($warnings | append $"($name): request URL could not be determined.")
  }

  {
    requests: 1
    folders: 0
    hooks: $hook_count
    warnings: $warnings
  }
}

# Merge import counters returned by recursive imports.
def merge-stats [left: record, right: record] {
  {
    requests: ($left.requests + $right.requests)
    folders: ($left.folders + $right.folders)
    hooks: ($left.hooks + $right.hooks)
    warnings: ($left.warnings ++ $right.warnings)
  }
}

# Recursively import Postman folders and requests.
def import-items [
  items: any
  target_dir: string
  inherited_auth: any
  inherited_pre: list
  inherited_post: list
  source_prefix: string
] {
  mut stats = {
    requests: 0
    folders: 0
    hooks: 0
    warnings: []
  }

  if $items == null {
    return $stats
  }

  for item in $items {
    if (has-field $item "request") {
      let result = (import-request $item $target_dir $inherited_auth $inherited_pre $inherited_post)
      $stats = (merge-stats $stats $result)
    } else if (has-field $item "item") {
      let folder_name = ($item | get -o name | default "Unnamed folder")
      let folder_dir = ($target_dir | path join (slug $folder_name))
      mkdir $folder_dir

      let folder_auth = if (has-field $item "auth") { $item.auth } else { $inherited_auth }
      let source = if ($source_prefix | is-empty) { $folder_name } else { $"($source_prefix)/($folder_name)" }
      let folder_pre = (event-scripts ($item | get -o event) "prerequest" $"folder: ($source)")
      let folder_post = (event-scripts ($item | get -o event) "test" $"folder: ($source)")

      let child = (
        import-items
          ($item | get -o item)
          $folder_dir
          $folder_auth
          ($inherited_pre ++ $folder_pre)
          ($inherited_post ++ $folder_post)
          $source
      )

      $stats = (merge-stats $stats $child)
      $stats.folders += 1
    }
  }

  $stats
}

# Import a Postman Collection v2.1 JSON export into the private nu-api workspace.
#
# Examples:
#   api import postman ./Work.postman_collection.json
#   api import postman ./Work.postman_collection.json --name work-api
#   api import postman ./Work.postman_collection.json --force
export def "api import postman" [
  file: string
  --name: string
  --force
] {
  let source_path = ($file | path expand)
  if not ($source_path | path exists) {
    error make { msg: $"Postman collection not found: ($source_path)" }
  }

  let collection = (open $source_path)
  let schema = ($collection | get -o info.schema | default "")

  if not ($schema | str contains "v2.1.0") {
    error make {
      msg: $"This importer currently supports Postman Collection v2.1 JSON. Found schema: ($schema)"
    }
  }

  let original_name = ($collection | get -o info.name | default "postman-import")
  let collection_name = if $name == null { slug $original_name } else { slug $name }
  let root = (api-home | path join "collections" $collection_name)

  if ($root | path exists) {
    if not $force {
      error make {
        msg: $"Collection already exists: ($collection_name). Use --force to replace it."
      }
    }
    rm --recursive --force $root
  }

  let requests_dir = ($root | path join "requests")
  let environments_dir = ($root | path join "environments")
  mkdir $requests_dir
  mkdir $environments_dir

  let variables = (variables-to-record ($collection | get -o variable))
  {
    name: $collection_name
    default_environment: "imported"
    variables: $variables
    auth: {}
  }
  | to nuon --pretty
  | save --force ($root | path join "collection.nuon")

  {} | to nuon --pretty | save --force ($environments_dir | path join "imported.nuon")

  let collection_pre = (event-scripts ($collection | get -o event) "prerequest" "collection")
  let collection_post = (event-scripts ($collection | get -o event) "test" "collection")
  let collection_auth = ($collection | get -o auth)

  let stats = (
    import-items
      ($collection | get -o item)
      $requests_dir
      $collection_auth
      $collection_pre
      $collection_post
      ""
  )

  print $"Imported Postman collection: ($collection_name)"
  print $"Location: ($root)"

  {
    collection: $collection_name
    requests: $stats.requests
    folders: $stats.folders
    generated_hooks: $stats.hooks
    manual_review: ($stats.warnings | length)
    warnings: $stats.warnings
  }
}

# Import a Postman environment JSON export into a nu-api collection.
#
# Uses the currently selected collection unless --collection is supplied.
#
# Examples:
#   api import postman-env ./Dev.postman_environment.json --environment dev
#   api import postman-env ./Prod.postman_environment.json --collection work-api --environment prod
export def "api import postman-env" [
  file: string
  --environment: string
  --collection: string
  --force
] {
  let source_path = ($file | path expand)
  if not ($source_path | path exists) {
    error make { msg: $"Postman environment not found: ($source_path)" }
  }

  let postman_env = (open $source_path)
  let collection_name = if $collection == null { selected-collection } else { $collection }
  let root = (api-home | path join "collections" $collection_name)

  if not ($root | path exists) {
    error make { msg: $"nu-api collection not found: ($collection_name)" }
  }

  let original_name = ($postman_env | get -o name | default "imported")
  let environment_name = if $environment == null { slug $original_name } else { slug $environment }
  let target = ($root | path join "environments" $"($environment_name).nuon")

  if ($target | path exists) and not $force {
    error make {
      msg: $"Environment already exists: ($environment_name). Use --force to replace it."
    }
  }

  let variables = (variables-to-record ($postman_env | get -o values))
  $variables | to nuon --pretty | save --force $target

  print $"Imported Postman environment: ($environment_name)"
  {
    collection: $collection_name
    environment: $environment_name
    variables: ($variables | columns | length)
    path: $target
  }
}
