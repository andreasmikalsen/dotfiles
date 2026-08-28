export use ./environment.nu [
  "api collections"
  "api collection use"
  "api collection init"
  "api env list"
  "api env use"
  "api status"
]

export use ./auth.nu [
  "api auth login"
  "api auth status"
  "api auth clear"
]

export use ./request.nu [
  "api list"
  "api show"
  "api run"
]
