use ./helpers.nu *

export def "obs env list" [] {
  let root = (observe-home | path join "environments")
  if not ($root | path exists) { return [] }
  let pattern = ($"($root)/*.nuon" | str replace --all '\' '/' | into glob)
  glob $pattern | each {|path| $path | path parse | get stem }
}

export def --env "obs env use" [name: string] {
  let path = (environment-path $name)
  if not ($path | path exists) {
    error make { msg: $"Observe environment not found: ($name)" }
  }
  $env.NU_OBSERVE_ENV = $name
  obs status
}

export def "obs status" [] {
  {
    home: (observe-home)
    environment: (if "NU_OBSERVE_ENV" in $env { $env.NU_OBSERVE_ENV } else { null })
  }
}
