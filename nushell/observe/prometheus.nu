use ./helpers.nu *

def prometheus-config [] {
  let environment = (environment-data)
  let config = ($environment | get -o prometheus)
  if $config == null {
    error make { msg: "Current observe environment has no 'prometheus' configuration" }
  }
  $config
}

export def prometheus-query [query: string] {
  let config = (prometheus-config)
  let base = ($config | get url | str trim --right --char "/")
  let headers = (auth-headers $config)
  let query_string = ({ query: $query } | url build-query)
  let response = (http get --headers $headers $"($base)/api/v1/query?($query_string)")
  if ($response | get -o status) != "success" {
    error make { msg: "Prometheus query did not return status=success" }
  }
  $response.data
}

export def prometheus-scalar [query: string] {
  let data = (prometheus-query $query)
  let result_type = ($data | get resultType)
  match $result_type {
    "scalar" => ($data | get result | get 1 | into float),
    "vector" => {
      let result = ($data | get result)
      if ($result | is-empty) { null } else { $result | first | get value | get 1 | into float }
    },
    _ => { error make { msg: $"Expected scalar/vector Prometheus result, got: ($result_type)" } }
  }
}

export def "obs check prometheus" [] {
  let data = (prometheus-query "vector(1)")
  { ok: true result_type: $data.resultType url: (environment-data | get prometheus.url) }
}

export def "obs query prometheus" [query: string] { prometheus-query $query }
