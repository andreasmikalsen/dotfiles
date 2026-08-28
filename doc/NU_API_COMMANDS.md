
# nu-api command reference

`nu-api` is the Nushell API-request engine stored in the dotfiles repo. Actual collections live separately under `$env.NU_API_HOME`, typically `%LOCALAPPDATA%\nu-api` on Windows.

## Navigation

### `nuapi`

Alias that changes directory to the private nu-api workspace:

```nu
nuapi
```

Equivalent to:

```nu
cd $env.NU_API_HOME
```

---

## Collections

### `api collection init <name>`

Create a new private collection with a starter environment, auth configuration, and health request.

```nu
api collection init work-api
```

Creates approximately:

```text
$NU_API_HOME/collections/work-api/
├── collection.nuon
├── environments/
│   └── local.nuon
└── requests/
    └── health.nuon
```

### `api collections`

List available private collections.

```nu
api collections
```

### `api collection use <name>`

Select a collection for the current Nushell session.

```nu
api collection use work-api
```

If the collection defines `default_environment`, that environment is selected automatically.

---

## Environments

### `api env list`

List environments in the currently selected collection.

```nu
api env list
```

### `api env use <name>`

Select an environment for the current Nushell session.

```nu
api env use dev
```

Environment variables are loaded from:

```text
$NU_API_HOME/collections/<collection>/environments/<name>.nuon
```

### `api status`

Show the current nu-api home, selected collection, and selected environment.

```nu
api status
```

---

## Requests

### `api list`

List saved requests recursively under the active collection.

```nu
api list
```

Example result:

```text
public/health
users/get-user
users/create-user
```

### `api show <request>`

Open/display the saved NUON request definition without executing it.

```nu
api show users/get-user
```

The `.nuon` suffix is optional.

### `api run <request>`

Execute a saved request.

```nu
api run users/get-user
```

The normal result is the full HTTP response record, including fields such as status, headers, and body.

Common Nushell pipelines:

```nu
api run users/get-user | get body
```

```nu
api run users/get-user
| get body
| select id name email
```

```nu
api run users/search
| get body
| where active == true
| sort-by name
```

```nu
api run users/get-user
| select status headers
```

```nu
api run users/get-user
| get body
| to json --pretty
| save --force user.json
```

---

## Authentication

### `api auth login [name]`

Force creation/refresh of an OAuth2 client-credentials access token.

Default auth name:

```nu
api auth login
```

Named auth configuration:

```nu
api auth login oauth
```

This currently applies to `oauth2_client_credentials` auth configurations.

### `api auth status`

Show cached OAuth token files for the selected collection/environment and their expiration times.

```nu
api auth status
```

### `api auth clear`

Delete cached OAuth tokens for the selected collection/environment.

```nu
api auth clear
```

The next OAuth request will fetch a new token.

---

## Supported auth types

### No authentication

```nu
{
  auth: null
}
```

### Basic

Named configuration in `collection.nuon`:

```nu
basic: {
  type: "basic"
  username: {
    secret: {
      provider: "env"
      key: "API_USERNAME"
    }
  }
  password: {
    secret: {
      provider: "prompt"
      label: "API password"
    }
  }
}
```

Request:

```nu
{
  auth: "basic"
}
```

### Bearer token

```nu
bearer: {
  type: "bearer"
  token: {
    secret: {
      provider: "env"
      key: "API_TOKEN"
    }
  }
}
```

### OAuth2 client credentials

```nu
oauth: {
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
  scope: "users.read"
}
```

OAuth access tokens are cached encrypted with Windows DPAPI for the current Windows user.

---

## Secret providers

### Environment variable

```nu
{
  secret: {
    provider: "env"
    key: "MY_SECRET"
  }
}
```

### Interactive prompt

```nu
{
  secret: {
    provider: "prompt"
    label: "Client secret"
  }
}
```

Prompt input is suppressed while typing.

---

## Request fields

Typical request:

```nu
{
  name: "Get user"
  method: "GET"
  path: "/v1/users/{{user_id}}"
  auth: "oauth"

  query: {
    include_permissions: true
  }

  headers: {
    Accept: "application/json"
  }
}
```

Supported HTTP methods:

```text
GET
POST
PUT
PATCH
DELETE
```

Body example:

```nu
body: {
  name: "Ada"
  active: true
}
```

Custom content type:

```nu
content_type: "application/json"
```

Full URL instead of `base_url + path`:

```nu
url: "https://example.invalid/v1/status"
```

---

## Templates

Collection and environment values can be referenced with:

```text
{{variable_name}}
```

Example:

```nu
path: "/{{api_version}}/users/{{user_id}}"
```

Collection variables are defined in `collection.nuon`; environment values are merged on top of them.

---

## Hooks

Requests can define pre- and post-request scripts:

```nu
hooks: {
  pre: "pre.nu"
  post: "post.nu"
}
```

Hook files live beside the request NUON file.

### Pre hook

Receives JSON describing:

```text
context
request
```

It must write valid JSON to stdout. It can modify the request before it is sent.

### Post hook

Receives JSON describing:

```text
context
request
response
```

It must write valid JSON to stdout. Its output becomes the result of `api run`.

Example post hook:

```nu
def main [] {
  let state = ($in | from json)

  if $state.response.status >= 400 {
    error make {
      msg: $"HTTP ($state.response.status)"
    }
  }

  $state.response.body
  | to json --raw
}
```

---

## Typical workflow

```nu
api collections
api collection use work-api
api env use dev
api status

api list
api show users/get-user
api run users/get-user | get body

api auth status
```

For OAuth troubleshooting:

```nu
api auth clear
api auth login oauth
api run users/get-user
```
