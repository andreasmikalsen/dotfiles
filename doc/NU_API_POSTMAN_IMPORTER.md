# nu-api Postman importer

Standalone importer for the existing `nu-api` engine. It does not modify the request/auth engine.

## Import a collection

```nu
api import postman ./Work.postman_collection.json
```

Override the generated collection name:

```nu
api import postman ./Work.postman_collection.json --name work-api
```

Replace an existing imported collection:

```nu
api import postman ./Work.postman_collection.json --name work-api --force
```

The importer currently targets Postman Collection v2.1 JSON exports.

## Import environments

Select the collection and import an environment:

```nu
api collection use work-api
api import postman-env ./Dev.postman_environment.json --env dev
api import postman-env ./Prod.postman_environment.json --env prod
```

Or name the destination collection explicitly:

```nu
api import postman-env ./Dev.postman_environment.json --collection work-api --env dev
```

## Converted automatically

- Nested Postman folders -> nested `requests/` directories
- GET/POST/PUT/PATCH/DELETE request definitions
- URLs and query parameters
- Headers
- Collection variables
- Postman environment variables
- Raw JSON bodies
- Raw text bodies
- `x-www-form-urlencoded` bodies
- Multipart text fields
- GraphQL bodies
- Basic auth
- Bearer auth
- OAuth2 client credentials when the Postman fields are available
- Collection/folder/request auth inheritance

## Scripts / hooks

Postman JavaScript cannot be safely translated to Nushell automatically.

When the collection has collection-, folder-, or request-level `prerequest` / `test` scripts, the importer creates `.pre.nu` / `.post.nu` hook files beside the request.

The original JavaScript is preserved as comments and marked `TODO`. The generated hooks are intentionally transparent until translated:

- pre hook returns the request state unchanged
- post hook returns the normal HTTP response unchanged

This means imported requests continue to behave normally while making every script that needs migration visible.

## Manual review warnings

The final import report includes warnings for things such as:

- unsupported auth types
- OAuth2 flows other than client credentials
- multipart file fields
- unsupported Postman body modes
- URLs that could not be determined

Run `api list` after import, inspect warnings, and use `api show <request>` before using sensitive requests.
