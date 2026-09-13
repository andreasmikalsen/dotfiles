use ./helpers.nu [collection-dir collection-config]

# Return true when a record contains a field, even when the value is null.
def has-field [value: any, field: string] {
  let kind = ($value | describe)
  if not ($kind | str starts-with "record") {
    return false
  }

  $field in ($value | columns)
}

# Merge only fields that are safe/useful to inherit from folders.
# Deeper folders override shallower folders.
def merge-inheritable [base: record, override: record] {
  mut result = $base

  # auth is special: null explicitly disables inherited auth.
  if (has-field $override "auth") {
    $result = ($result | upsert auth $override.auth)
  }

  if (has-field $override "headers") {
    let incoming = ($override | get -o headers)
    if $incoming != null {
      let current = ($result | get -o headers | default {})
      $result = ($result | upsert headers ($current | merge $incoming))
    }
  }

  if (has-field $override "variables") {
    let incoming = ($override | get -o variables)
    if $incoming != null {
      let current = ($result | get -o variables | default {})
      $result = ($result | upsert variables ($current | merge $incoming))
    }
  }

  $result
}

# Return all directories from requests/ down to the request's parent folder.
def folder-chain [request_file: string] {
  let root = (collection-dir | path join "requests" | path expand)
  let request_dir = ($request_file | path dirname | path expand)
  let relative = ($request_dir | path relative-to $root)

  mut directories = [$root]
  mut current = $root

  for part in ($relative | path split) {
    if (($part | into string | str trim) | is-empty) or $part == "." {
      continue
    }

    $current = ($current | path join $part)
    $directories = ($directories | append $current)
  }

  $directories
}

# Resolve collection defaults + every _folder.nuon from shallowest to deepest.
export def folder-settings [request_file: string] {
  let config = (collection-config)
  let defaults = ($config | get -o defaults | default {})
  mut result = $defaults

  for dir in (folder-chain $request_file) {
    let folder_file = ($dir | path join "_folder.nuon")

    if ($folder_file | path exists) {
      let settings = (open $folder_file)
      $result = (merge-inheritable $result $settings)
    }
  }

  $result
}

# Apply inherited folder settings to a request.
# Request-level values always win. auth:null disables inherited auth.
export def apply-folder-inheritance [request_file: string, request: record] {
  let inherited = (folder-settings $request_file)
  mut result = $request

  if not (has-field $request "auth") and (has-field $inherited "auth") {
    $result = ($result | upsert auth $inherited.auth)
  }

  if (has-field $inherited "headers") {
    let inherited_headers = ($inherited | get -o headers | default {})
    let request_headers = ($request | get -o headers | default {})
    $result = ($result | upsert headers ($inherited_headers | merge $request_headers))
  }

  if (has-field $inherited "variables") {
    let inherited_variables = ($inherited | get -o variables | default {})
    let request_variables = ($request | get -o variables | default {})
    $result = ($result | upsert variables ($inherited_variables | merge $request_variables))
  }

  $result
}
