export use ./environment.nu [
  "db list"
  "db use"
  "db env list"
  "db env use"
  "db status"
  "db show"
  "db init"
]

export use ./auth.nu [
  "db auth status"
]

export use ./connect.nu [
  "db connect"
  "db query"
  "db exec"
  "db tui"
]
