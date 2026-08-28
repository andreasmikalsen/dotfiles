def main [] {
  let state = ($in | from json)

  let current_headers = (
    $state.request
    | get -o headers
    | default {}
  )

  $state
  | update request { |request|
      $request
      | upsert headers (
          $current_headers
          | upsert "X-Request-ID" (random uuid)
          | upsert "X-Pre-Hook" "nushell"
        )
    }
  | to json --raw
}
