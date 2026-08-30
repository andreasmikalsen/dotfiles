use ./helpers.nu *

def require-command [name: string] {
  if (which $name | is-empty) {
    error make { msg: $"Required command not found: ($name)" }
  }
}

def azure-token [auth: record] {
  require-command "az"

  let subscription = ($auth | get -o subscription)
  if $subscription == null {
    error make { msg: "Azure auth requires 'subscription'" }
  }

  let switch_result = (
    ^az account set --subscription $subscription
    | complete
  )

  if $switch_result.exit_code != 0 {
    error make {
      msg: $"Failed to switch Azure subscription to '($subscription)'\n($switch_result.stderr)"
    }
  }

  let resource = ($auth | get -o resource)
  let resource_type = ($auth | get -o resource_type)

  let token_result = if $resource != null {
    ^az account get-access-token --subscription $subscription --resource $resource --query accessToken --output tsv
    | complete
  } else {
    let selected_resource_type = if $resource_type == null { "oss-rdbms" } else { $resource_type }

    ^az account get-access-token --subscription $subscription --resource-type $selected_resource_type --query accessToken --output tsv
    | complete
  }

  if $token_result.exit_code != 0 {
    error make {
      msg: $"Failed to acquire Azure database token\n($token_result.stderr)"
    }
  }

  let token = ($token_result.stdout | str trim)

  if ($token | is-empty) {
    error make { msg: "Azure CLI returned an empty access token" }
  }

  $token
}

export def acquire-password [ctx: record] {
  let auth = ($ctx.environment | get -o auth)

  if $auth == null {
    return null
  }

  let auth_type = ($auth | get -o type)

  match $auth_type {
    "password" => {
      let password = ($auth | get -o password)
      if $password == null {
        error make { msg: "Password auth requires 'password'" }
      }
      $password
    }

    "env" => {
      let key = ($auth | get -o key)
      if $key == null {
        error make { msg: "Environment auth requires 'key'" }
      }

      let value = ($env | get -o $key)
      if $value == null {
        error make { msg: $"Environment variable '($key)' is not set" }
      }

      $value
    }

    "prompt" => {
      let label = ($auth | get -o label)
      let prompt = if $label == null { "Database password" } else { $label }
      input --suppress-output $"($prompt): "
    }

    "azure" => {
      azure-token $auth
    }

    _ => {
      error make { msg: $"Unsupported database auth type: ($auth_type)" }
    }
  }
}

export def "db auth status" [] {
  let ctx = (context)
  let auth = ($ctx.environment | get -o auth)
  let auth_type = if $auth == null { null } else { $auth | get -o type }

  if $auth_type != "azure" {
    return {
      database: $ctx.database_name
      environment: $ctx.environment_name
      auth_type: $auth_type
    }
  }

  let configured_subscription = ($auth | get -o subscription)
  let az_available = not (which az | is-empty)

  let active_account = if $az_available {
    let result = (^az account show --output json | complete)

    if $result.exit_code == 0 {
      let account = ($result.stdout | from json)
      {
        name: ($account | get -o name)
        id: ($account | get -o id)
        tenant: ($account | get -o tenantId)
        user: ($account | get -o user.name)
      }
    } else {
      null
    }
  } else {
    null
  }

  {
    database: $ctx.database_name
    environment: $ctx.environment_name
    auth_type: $auth_type
    configured_subscription: $configured_subscription
    azure_cli_available: $az_available
    active_account: $active_account
  }
}
