use ./helpers.nu *

def dpapi-script [] {
  $nu.default-config-dir
  | path join "api" "dpapi.ps1"
}

def token-dir [] {
  let dir = (api-home | path join "state" "tokens")
  mkdir $dir
  $dir
}

def token-path [name: string] {
  token-dir
  | path join $"(selected-collection)--(selected-environment)--($name).token"
}

def save-token [name: string, token: record] {
  let encrypted = (
    $token
    | to json
    | ^powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (dpapi-script) protect
    | str trim
  )

  $encrypted | save --force (token-path $name)
}

def load-token [name: string] {
  let path = (token-path $name)

  if not ($path | path exists) {
    return null
  }

  try {
    open --raw $path
    | ^powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (dpapi-script) unprotect
    | from json
  } catch {
    null
  }
}

def oauth-client-credentials [
  name: string
  auth: record
  variables: record
  --force
] {
  if not $force {
    let cached = (load-token $name)

    if $cached != null {
      let expires_at = (
        $cached.expires_at
        | into datetime
      )

      if $expires_at > (date now) {
        return $cached
      }
    }
  }

  let token_url = (
    resolve-value ($auth | get token_url) $variables
  )

  let client_id = (
    resolve-value ($auth | get client_id) $variables
  )

  let client_secret = (
    resolve-value ($auth | get client_secret) $variables
  )

  let scope_raw = ($auth | get -o scope)

  mut form = {
    grant_type: "client_credentials"
    client_id: $client_id
    client_secret: $client_secret
  }

  if ($scope_raw != null and $scope_raw != "") {
    $form = (
      $form
      | upsert scope (resolve-value $scope_raw $variables)
    )
  }

  let extra = ($auth | get -o extra)

  if $extra != null {
    let resolved_extra = (resolve-value $extra $variables)
    $form = ($form | merge $resolved_extra)
  }

  let response = (
    http post
      --content-type "application/x-www-form-urlencoded"
      --full
      --allow-errors
      --pool
      $token_url
      ($form | url build-query)
  )

  if $response.status >= 400 {
    error make {
      msg: $"OAuth token request failed: HTTP ($response.status)"
    }
  }

  let access_token = ($response.body | get -o access_token)

  if $access_token == null {
    error make {
      msg: "OAuth response did not contain access_token"
    }
  }

  let expires_in_raw = ($response.body | get -o expires_in)

  let expires_in = if $expires_in_raw == null {
    3600
  } else {
    $expires_in_raw | into int
  }

  # Expire locally 30 seconds early.
  let expires_at = (
    (date now)
    + (($expires_in - 30) * 1sec)
  )

  let token = {
    access_token: $access_token
    token_type: "Bearer"
    expires_at: ($expires_at | into string)
  }

  save-token $name $token

  $token
}

export def resolve-auth-headers [
  auth_ref: any
  config: record
  variables: record
] {
  if $auth_ref == null {
    return {}
  }

  let auth_name = if ($auth_ref | describe) == "string" {
    $auth_ref
  } else {
    "inline"
  }

  let raw_auth = if ($auth_ref | describe) == "string" {
    let auths = ($config | get -o auth)

    if $auths == null {
      error make {
        msg: $"Collection has no auth configuration: ($auth_ref)"
      }
    }

    let value = ($auths | get -o $auth_ref)

    if $value == null {
      error make {
        msg: $"Unknown auth configuration: ($auth_ref)"
      }
    }

    $value
  } else {
    $auth_ref
  }

  let auth = (render-template $raw_auth $variables)
  let auth_type = ($auth | get type)

  match $auth_type {
    "basic" => {
      let username = (
        resolve-value ($auth | get username) $variables
      )

      let password = (
        resolve-value ($auth | get password) $variables
      )

      let encoded = (
        $"($username):($password)"
        | encode base64
      )

      {
        Authorization: $"Basic ($encoded)"
      }
    }

    "bearer" => {
      let token = (
        resolve-value ($auth | get token) $variables
      )

      {
        Authorization: $"Bearer ($token)"
      }
    }

    "oauth2_client_credentials" => {
      let token = (
        oauth-client-credentials
          $auth_name
          $auth
          $variables
      )

      {
        Authorization: $"Bearer ($token.access_token)"
      }
    }

    _ => {
      error make {
        msg: $"Unsupported auth type: ($auth_type)"
      }
    }
  }
}

export def "api auth login" [name: string = "default"] {
  let ctx = (context)

  let auths = ($ctx.config | get -o auth)

  if $auths == null {
    error make {
      msg: "Collection has no auth configurations"
    }
  }

  let auth = ($auths | get -o $name)

  if $auth == null {
    error make {
      msg: $"Unknown auth configuration: ($name)"
    }
  }

  let rendered = (render-template $auth $ctx.variables)

  if ($rendered.type != "oauth2_client_credentials") {
    error make {
      msg: "'api auth login' currently applies to OAuth2 client_credentials auth"
    }
  }

  let token = (
    oauth-client-credentials
      $name
      $rendered
      $ctx.variables
      --force
  )

  {
    auth: $name
    expires_at: $token.expires_at
  }
}

export def "api auth status" [] {
  let root = (token-dir)

  let pattern = (
    $"(selected-collection)--(selected-environment)--*.token"
  )

  glob ($root | path join $pattern)
  | each {|path|
      let token = (
        try {
          open --raw $path
          | ^powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (dpapi-script) unprotect
          | from json
        } catch {
          null
        }
      )

      {
        name: ($path | path basename)
        expires_at: (
          if $token == null {
            null
          } else {
            $token.expires_at
          }
        )
      }
    }
}

export def "api auth clear" [] {
  let root = (token-dir)

  let pattern = (
    $"(selected-collection)--(selected-environment)--*.token"
  )

  glob ($root | path join $pattern)
  | each {|path| rm --force $path }

  print "OAuth token cache cleared."
}
