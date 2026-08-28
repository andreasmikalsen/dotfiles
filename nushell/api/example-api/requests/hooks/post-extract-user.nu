def main [] {
  let state = ($in | from json)

  if $state.response.status >= 400 {
    error make {
      msg: $"Request failed with HTTP ($state.response.status)"
    }
  }

  {
    status: $state.response.status
    request_name: $state.request.name
    user: $state.response.body
  }
  | to json --raw
}
