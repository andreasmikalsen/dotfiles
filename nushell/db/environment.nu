use ./helpers.nu *

export def "db list" [] {
  let root = (db-home | path join "databases")

  if not ($root | path exists) {
    return []
  }

  ls $root
  | where type == dir
  | get name
  | each {|path| $path | path basename }
}

export def --env "db use" [name: string] {
  let root = (db-home | path join "databases" $name)

  if not ($root | path exists) {
    error make { msg: $"Database not found: ($name)" }
  }

  $env.NU_DB_DATABASE = $name

  let config_path = ($root | path join "database.nuon")
  if ($config_path | path exists) {
    let config = (open $config_path)
    let default_environment = ($config | get -o default_environment)

    if $default_environment != null {
      $env.NU_DB_ENV = $default_environment
    }
  }

  db status
}

export def "db env list" [] {
  let root = (database-dir | path join "environments")

  if not ($root | path exists) {
    return []
  }

  glob ($root | path join "*.nuon")
  | each {|path| $path | path parse | get stem }
}

export def --env "db env use" [name: string] {
  let path = (database-dir | path join "environments" $"($name).nuon")

  if not ($path | path exists) {
    error make { msg: $"Database environment not found: ($name)" }
  }

  $env.NU_DB_ENV = $name
  db status
}

export def "db status" [] {
  {
    home: (db-home)
    database: (if "NU_DB_DATABASE" in $env { $env.NU_DB_DATABASE } else { null })
    environment: (if "NU_DB_ENV" in $env { $env.NU_DB_ENV } else { null })
  }
}

export def "db show" [] {
  let ctx = (context)
  let auth = ($ctx.environment | get -o auth)
  let auth_type = if $auth == null { null } else { $auth | get -o type }

  {
    database: $ctx.database_name
    environment: $ctx.environment_name
    type: $ctx.type
    host: ($ctx.environment | get -o host)
    port: ($ctx.environment | get -o port)
    database_name: ($ctx.environment | get -o database)
    username: ($ctx.environment | get -o username)
    sslmode: ($ctx.environment | get -o sslmode)
    auth_type: $auth_type
  }
}

export def "db init" [name: string] {
  let root = (db-home | path join "databases" $name)

  if ($root | path exists) {
    error make { msg: $"Database already exists: ($name)" }
  }

  mkdir $root
  mkdir ($root | path join "environments")

  {
    name: $name
    type: "postgres"
    default_environment: "local"
  }
  | to nuon --pretty
  | save ($root | path join "database.nuon")

  {
    host: "localhost"
    port: 5432
    database: $name
    username: "postgres"
    sslmode: "disable"
    auth: {
      type: "password"
      password: "postgres"
    }
  }
  | to nuon --pretty
  | save ($root | path join "environments" "local.nuon")

  {
    host: $"($name)-test.example.postgres.database.azure.com"
    port: 5432
    database: $name
    username: "you@company.example"
    sslmode: "require"
    auth: {
      type: "azure"
      subscription: "TEST-SUBSCRIPTION"
      resource_type: "oss-rdbms"
    }
  }
  | to nuon --pretty
  | save ($root | path join "environments" "test.nuon")

  {
    host: $"($name)-prod.example.postgres.database.azure.com"
    port: 5432
    database: $name
    username: "you@company.example"
    sslmode: "require"
    auth: {
      type: "azure"
      subscription: "PROD-SUBSCRIPTION"
      resource_type: "oss-rdbms"
    }
  }
  | to nuon --pretty
  | save ($root | path join "environments" "prod.nuon")

  print $"Created database config: ($root)"
}
