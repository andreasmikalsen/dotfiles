export use ./help.nu [pod]

export use ./commands.nu [
  "pod status"
  "pod ps"

  "pod machine status"
  "pod machine start"
  "pod machine stop"
  "pod machine restart"

  "pod compose up"
  "pod compose down"
  "pod compose restart"
  "pod compose ps"
  "pod compose logs"

  "pod container start"
  "pod container stop"
  "pod container restart"
  "pod container logs"
  "pod container stats"
]

export use ./tui.nu [
  "pod tui"
]
