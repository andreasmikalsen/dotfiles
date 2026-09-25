use ../db/mod.nu ["db use" "db query"]
use ./helpers.nu *

export def observe-sql-query [database: string, environment: string, query: string] {
  db use $database $environment | ignore
  db query $query
}

export def "obs query sql" [database: string, query_file: string, --environment: string] {
  let target_environment = if $environment == null { selected-environment } else { $environment }
  let query = (sql-file $query_file)
  observe-sql-query $database $target_environment $query
}
