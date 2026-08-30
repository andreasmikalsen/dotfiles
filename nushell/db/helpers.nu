export def db-home [] {
  if "NU_DB_HOME" not-in $env {
    error make { msg: "NU_DB_HOME is not configured" }
  }

  $env.NU_DB_HOME | path expand
}

export def selected-database [] {
  if "NU_DB_DATABASE" not-in $env {
    error make { msg: "No database selected. Run: db use <name>" }
  }

  $env.NU_DB_DATABASE
}

export def selected-environment [] {
  if "NU_DB_ENV" not-in $env {
    error make { msg: "No database environment selected. Run: db env use <name>" }
  }

  $env.NU_DB_ENV
}

export def database-dir [] {
  db-home | path join "databases" (selected-database)
}

export def database-config [] {
  let path = (database-dir | path join "database.nuon")

  if not ($path | path exists) {
    error make { msg: $"Database config not found: ($path)" }
  }

  open $path
}

export def environment-data [] {
  let path = (database-dir | path join "environments" $"(selected-environment).nuon")

  if not ($path | path exists) {
    error make { msg: $"Database environment not found: ($path)" }
  }

  open $path
}

export def context [] {
  let config = (database-config)
  let environment = (environment-data)
  let database_type = ($config | get -o type)

  if $database_type == null {
    error make { msg: "database.nuon must contain a 'type' field" }
  }

  {
    home: (db-home)
    database_name: (selected-database)
    environment_name: (selected-environment)
    database_dir: (database-dir)
    type: $database_type
    config: $config
    environment: $environment
  }
}
