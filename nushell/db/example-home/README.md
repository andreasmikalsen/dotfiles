
# nu-db

A small Nushell database launcher that mirrors the structure of `nu-api`.

## What goes in Git

Copy `engine/db/` to your dotfiles repo as:

```text
nushell/db/
├── mod.nu
├── helpers.nu
├── environment.nu
├── auth.nu
├── connect.nu
└── help.nu
```

## What stays private

Copy the contents of `example-home/` into `%LOCALAPPDATA%\nu-db` and replace the fake connection details.

Do **not** junction `%LOCALAPPDATA%\nu-db` into the dotfiles repository.

## Quick start

```nu
db list
db use orders
db env use local
db show
db connect
```

For Azure PostgreSQL:

```nu
db env use test
db auth status
db connect
```

The engine switches to the configured Azure subscription and requests a fresh `oss-rdbms` access token immediately before launching `psql`.

See `NU_DB_COMMANDS.md` for the full command reference.
