use ./helpers.nu *
use ./auth.nu acquire-password

def require-command [name: string] {
  if (which $name | is-empty) {
    error make { msg: $"Required command not found: ($name)" }
  }
}

def postgres-env [ctx: record, password: any] {
  let connection = $ctx.environment

  let host = ($connection | get -o host)
  let port = ($connection | get -o port)
  let database = ($connection | get -o database)
  let username = ($connection | get -o username)

  if $host == null or $port == null or $database == null or $username == null {
    error make { msg: "PostgreSQL environment requires host, port, database, and username" }
  }

  let base = {
    PGHOST: $host
    PGPORT: ($port | into string)
    PGDATABASE: $database
    PGUSER: $username
  }

  let with_password = if $password == null {
    $base
  } else {
    $base | upsert PGPASSWORD $password
  }

  let sslmode = ($connection | get -o sslmode)
  if $sslmode == null {
    $with_password
  } else {
    $with_password | upsert PGSSLMODE $sslmode
  }
}

def connect-postgres [ctx: record] {
  require-command "psql"

  let password = (acquire-password $ctx)
  let environment = (postgres-env $ctx $password)

  with-env $environment {
    ^psql
  }
}

def connect-redis [ctx: record] {
  require-command "redis-cli"

  let connection = $ctx.environment
  let host = ($connection | get -o host)
  let port = ($connection | get -o port)
  let database = ($connection | get -o database)

  if $host == null or $port == null {
    error make { msg: "Redis environment requires host and port" }
  }

  let db_index = if $database == null { 0 } else { $database }
  let password = (acquire-password $ctx)

  let redis_env = if $password == null {
    {}
  } else {
    { REDISCLI_AUTH: $password }
  }

  let username = ($connection | get -o username)
  let tls = ($connection | get -o tls)

  if $username != null and $tls == true {
    with-env $redis_env {
      ^redis-cli --tls --user $username -h $host -p ($port | into string) -n ($db_index | into string)
    }
  } else if $username != null {
    with-env $redis_env {
      ^redis-cli --user $username -h $host -p ($port | into string) -n ($db_index | into string)
    }
  } else if $tls == true {
    with-env $redis_env {
      ^redis-cli --tls -h $host -p ($port | into string) -n ($db_index | into string)
    }
  } else {
    with-env $redis_env {
      ^redis-cli -h $host -p ($port | into string) -n ($db_index | into string)
    }
  }
}

def connect-rainfrog [ctx: record] {
  require-command "rainfrog"

  if $ctx.type != "postgres" {
    error make {
      msg: "Rainfrog currently supports nu-db PostgreSQL connections only"
    }
  }

  let connection = $ctx.environment

  let host = ($connection | get -o host)
  let port = ($connection | get -o port)
  let database = ($connection | get -o database)
  let username = ($connection | get -o username)

  if $host == null or $port == null or $database == null or $username == null {
    error make {
      msg: "PostgreSQL environment requires host, port, database, and username"
    }
  }

  let password = (acquire-password $ctx)

  let encoded_username = ($username | url encode --all)
  let encoded_database = ($database | url encode --all)

  let credentials = if $password == null {
    $"($encoded_username)@"
  } else {
    let encoded_password = ($password | url encode --all)
    $"($encoded_username):($encoded_password)@"
  }

  let sslmode = ($connection | get -o sslmode)

  let query = if $sslmode == null {
    ""
  } else {
    $"?sslmode=($sslmode)"
  }

  let connection_url = $"postgres://($credentials)($host):($port)/($encoded_database)($query)"

  with-env {
    DATABASE_URL: $connection_url
  } {
    ^rainfrog
  }
}

export def "db tui" [] {
  let ctx = (context)
  connect-rainfrog $ctx
}

export def "db connect" [] {
  let ctx = (context)

  match $ctx.type {
    "postgres" => (connect-postgres $ctx)
    "redis" => (connect-redis $ctx)
    _ => { error make { msg: $"Unsupported database type: ($ctx.type)" } }
  }
}

export def "db query" [sql: string] {
  let ctx = (context)

  if $ctx.type != "postgres" {
    error make { msg: "db query currently supports PostgreSQL only" }
  }

  require-command "psql"

  let password = (acquire-password $ctx)
  let environment = (postgres-env $ctx $password)

  let result = with-env $environment {
    ^psql --csv --command $sql | complete
  }

  if $result.exit_code != 0 {
    error make { msg: $"Database query failed\n($result.stderr)" }
  }

  let output = ($result.stdout | str trim)
  if ($output | is-empty) {
    return []
  }

  $output | from csv
}

export def "db exec" [sql: string] {
  let ctx = (context)

  if $ctx.type != "postgres" {
    error make { msg: "db exec currently supports PostgreSQL only" }
  }

  require-command "psql"

  let password = (acquire-password $ctx)
  let environment = (postgres-env $ctx $password)

  let result = with-env $environment {
    ^psql --command $sql | complete
  }

  if $result.exit_code != 0 {
    error make { msg: $"Database command failed\n($result.stderr)" }
  }

  $result.stdout | str trim
}
