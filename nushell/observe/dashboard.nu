use ./helpers.nu *
use ./prometheus.nu [prometheus-scalar]
use ./sql.nu [observe-sql-query]

def scalar-from-sql [result: any, field?: string] {
  if $result == null { return null }
  let kind = ($result | describe)
  if not ($kind | str starts-with "list") { return $result }
  if ($result | is-empty) { return null }
  let first = ($result | first)
  let first_kind = ($first | describe)
  if not ($first_kind | str starts-with "record") { return $first }
  if $field != null { return ($first | get -o $field) }
  let columns = ($first | columns)
  if ($columns | length) == 1 { $first | get ($columns | first) } else { $first | to json --raw }
}

def panel-value [panel: record, observe_environment: string] {
  let source = ($panel | get source)
  match $source {
    "prometheus" => { prometheus-scalar ($panel | get query) },
    "sql" => {
      let db_environment = ($panel | get -o environment | default $observe_environment)
      let query = if (($panel | get -o query_file) != null) { sql-file ($panel | get query_file) } else { $panel | get query }
      let result = (observe-sql-query ($panel | get database) $db_environment $query)
      scalar-from-sql $result ($panel | get -o field)
    },
    _ => { error make { msg: $"Unsupported dashboard source: ($source)" } }
  }
}

def format-value [value: any, panel: record] {
  if $value == null { return "-" }
  let suffix = ($panel | get -o suffix | default "")
  let decimals = ($panel | get -o decimals)
  let formatted = if $decimals == null {
    $value | into string
  } else {
    try { $value | into float | math round --precision $decimals | into string } catch { $value | into string }
  }
  $"($formatted)($suffix)"
}

def panel-status [value: any, panel: record] {
  if $value == null { return "unknown" }
  let warning = ($panel | get -o warning)
  let critical = ($panel | get -o critical)
  if $critical != null and $value >= $critical { "critical" } else if $warning != null and $value >= $warning { "warning" } else { "ok" }
}

def dashboard-once [name: string] {
  let dashboard = (dashboard-data $name)
  let observe_environment = (selected-environment)
  let panels = ($dashboard | get -o panels | default [])
  print $"($dashboard.name | default $name) • ($observe_environment)"
  print $"Updated: (date now | format date '%Y-%m-%d %H:%M:%S')"
  print ""
  $panels | each {|panel|
    try {
      let value = (panel-value $panel $observe_environment)
      { status: (panel-status $value $panel) metric: ($panel | get title) value: (format-value $value $panel) source: ($panel | get source) }
    } catch {|error|
      { status: "error" metric: ($panel | get title) value: ($error.msg | default "query failed") source: ($panel | get source) }
    }
  } | table
}

export def "obs dashboard" [name?: string, --once] {
  let dashboard_name = if $name == null { "overview" } else { $name }
  let dashboard = (dashboard-data $dashboard_name)
  let refresh = ($dashboard | get -o refresh | default 10sec)
  if $once { dashboard-once $dashboard_name; return }
  loop {
    clear
    dashboard-once $dashboard_name
    print ""
    print $"Refreshing every ($refresh). Ctrl+C to stop."
    sleep $refresh
  }
}
