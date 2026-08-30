# nu-db command reference

`nu-db` keeps the engine in your dotfiles and the actual database definitions outside Git at `%LOCALAPPDATA%\nu-db`.

## Selection

```nu
# List all configured databases
db list

# Create a PostgreSQL skeleton with local/test/prod
db init orders

# Select a database
db use orders

# Show current database/environment selection
db status

# Show the active connection without printing passwords/tokens
db show
```

## Environments

```nu
db env list
db env use local
db env use test
db env use prod
```

Selecting a database automatically selects its `default_environment` from `database.nuon`.

## Authentication

```nu
db auth status
```

Supported auth blocks:

### Hardcoded password

```nu
{
  type: "password"
  password: "postgres"
}
```

### Environment variable

```nu
{
  type: "env"
  key: "DATABASE_PASSWORD"
}
```

### Prompt every time

```nu
{
  type: "prompt"
  label: "Database password"
}
```

### Azure / Microsoft Entra PostgreSQL token

```nu
{
  type: "azure"
  subscription: "YOUR-SUBSCRIPTION"
  resource_type: "oss-rdbms"
}
```

When connecting, nu-db:

1. switches the Azure CLI active subscription;
2. requests a fresh PostgreSQL access token;
3. passes that token to `psql` as `PGPASSWORD`;
4. does not cache or write the token to disk.

You can replace `resource_type` with an explicit resource if your environment requires it:

```nu
{
  type: "azure"
  subscription: "YOUR-SUBSCRIPTION"
  resource: "https://ossrdbms-aad.database.windows.net"
}
```

## Connect

```nu
db connect
```

For `type: "postgres"`, this launches `psql` using `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`, and optionally `PGSSLMODE`.

For `type: "redis"`, this launches `redis-cli`. Passwords are passed through `REDISCLI_AUTH` rather than as a command-line argument.

## Query PostgreSQL into Nushell

```nu
db query "select id, email from users limit 20"
```

`db query` uses `psql --csv` and converts the result into Nushell records, so normal Nu pipelines work:

```nu
db query "select id, email, active from users" | where active == true

db query "select id, email from users" | where email =~ "@company" | select id email

db query "select id from orders" | get id

db query "select status, count(*) as count from orders group by status" | sort-by count -r
```

For SQL where you want the raw psql output instead of structured rows:

```nu
db exec "update users set active = false where id = 123"
```

## Private workspace layout

```text
%LOCALAPPDATA%\nu-db\
└── databases\
    ├── orders\
    │   ├── database.nuon
    │   └── environments\
    │       ├── local.nuon
    │       ├── test.nuon
    │       └── prod.nuon
    └── cache\
        ├── database.nuon
        └── environments\
            ├── local.nuon
            ├── test.nuon
            └── prod.nuon
```

Do not junction this private directory into the dotfiles repository.

## Root help

```nu
db
db --help
db -h
help db
```

## Nushell config

```nu
use ($nu.default-config-dir | path join "db" "mod.nu") *
use ($nu.default-config-dir | path join "db" "help.nu") db

alias nudb = cd $env.NU_DB_HOME
```

## setup.ps1

```powershell
$dbHome = Join-Path $env:LOCALAPPDATA "nu-db"
$env:NU_DB_HOME = $dbHome
[Environment]::SetEnvironmentVariable("NU_DB_HOME", $dbHome, "User")

New-Item -ItemType Directory -Force -Path $dbHome | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $dbHome "databases") | Out-Null
```

## Required clients

- PostgreSQL: `psql`
- Azure token environments: Azure CLI (`az`)
- Redis: `redis-cli`

The engine checks for these commands when they are actually needed.
