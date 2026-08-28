# nu-api example collection

This directory is a **fake/private-workspace example** for the Nushell `nu-api` engine. Copy it into your private `NU_API_HOME/collections/` directory and modify it there. Do not put real company URLs, credentials, tokens, request bodies, or production data in your public dotfiles repo.

## Layout

```text
example-api/
├── collection.nuon
├── environments/
│   ├── local.nuon
│   └── dev.nuon
└── requests/
    ├── public/
    │   ├── health.nuon
    │   └── search.nuon
    ├── auth/
    │   ├── basic.nuon
    │   ├── bearer.nuon
    │   └── oauth.nuon
    ├── users/
    │   ├── get-user.nuon
    │   ├── create-user.nuon
    │   ├── replace-user.nuon
    │   ├── patch-user.nuon
    │   └── delete-user.nuon
    └── hooks/
        ├── get-user-with-hooks.nuon
        ├── pre-add-request-id.nu
        └── post-extract-user.nu
```

## Try it

Copy this folder to:

```text
%LOCALAPPDATA%\nu-api\collections\example-api
```

Then:

```nu
api collection use example-api
api env use local
api list
api show users/get-user
```

The URLs are intentionally fake except for the localhost environment, so requests only work if you have a compatible API running locally.

## Authentication examples

### No authentication

```nu
api run public/health
```

### Basic auth

`collection.nuon` reads the username from an environment variable and prompts for the password:

```nu
$env.NU_API_EXAMPLE_BASIC_USER = "demo-user"
api run auth/basic
```

### Bearer token

```nu
$env.NU_API_EXAMPLE_BEARER_TOKEN = "replace-me"
api run auth/bearer
```

### OAuth2 client credentials

```nu
$env.NU_API_EXAMPLE_CLIENT_ID = "example-client"
api auth login oauth
api run auth/oauth
```

The client secret is prompted securely. Access tokens are cached by the engine using Windows DPAPI.

## HTTP methods

```nu
api run users/get-user
api run users/create-user
api run users/replace-user
api run users/patch-user
api run users/delete-user
```

These demonstrate GET, POST, PUT, PATCH, and DELETE.

## Query parameters

`public/search.nuon` demonstrates a `query` record:

```nu
api run public/search
```

The engine converts it to a URL query string.

## Environment and collection variables

Templates use `{{name}}` syntax:

```text
/{{api_version}}/users/{{user_id}}
```

`api_version` comes from `collection.nuon`; `user_id` comes from the selected environment. Environment values override collection variables with the same name.

## Pre-request hook

`hooks/pre-add-request-id.nu` receives the request state as JSON on stdin. It adds headers before the HTTP request is sent.

```nu
api run hooks/get-user-with-hooks
```

The hook adds:

```text
X-Request-ID: <generated UUID>
X-Pre-Hook: nushell
```

## Post-response hook

`hooks/post-extract-user.nu` receives the request + response and returns a smaller record containing only status, request name, and the response body.

```nu
api run hooks/get-user-with-hooks
```

## Working with responses in Nushell

Without a post hook, `api run` returns the full response record.

Get only the body:

```nu
api run users/get-user | get body
```

Select fields:

```nu
api run users/get-user
| get body
| select id name email
```

Inspect status and headers:

```nu
api run users/get-user
| select status headers
```

Filter a list response:

```nu
api run public/search
| get body
| where active == true
| select id name email
```

Sort data:

```nu
api run public/search
| get body
| sort-by name
```

Count results:

```nu
api run public/search
| get body
| length
```

Save a response body:

```nu
api run users/get-user
| get body
| to json --pretty
| save --force user.json
```

Inspect the shape of a response while developing a request:

```nu
api run users/get-user | describe
api run users/get-user | get body | describe
```

## Inline authentication

The request engine also accepts an auth record directly instead of a named auth configuration. Example:

```nu
{
  name: "Inline bearer example"
  method: "GET"
  path: "/v1/profile"
  auth: {
    type: "bearer"
    token: {
      secret: {
        provider: "env"
        key: "NU_API_EXAMPLE_BEARER_TOKEN"
      }
    }
  }
}
```

Named auth configurations are usually cleaner when multiple requests share the same authentication.

## Security notes

- Keep real collections under `NU_API_HOME`, not in the dotfiles repo.
- Prefer `secret` references instead of plaintext credentials in NUON files.
- `provider: "prompt"` keeps the value out of the request file and does not echo it while typing.
- OAuth access-token cache files are protected with Windows DPAPI for the current Windows user.
- Avoid putting production payloads or sensitive customer data in request examples that are committed to Git.
