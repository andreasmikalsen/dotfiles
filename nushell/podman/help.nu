# Podman + Compose workflow for Nushell.
#
# TUI:
#   pod tui
#
# TUI navigation:
#   j / k       move down / up
#   h / l       hide / show details pane
#   /           enter search mode
#   Esc         leave search mode
#   q           quit
#
# Overview:
#   pod status
#   pod ps
#
# Podman machine:
#   pod machine status
#   pod machine start
#   pod machine stop
#   pod machine restart
#
# Compose project:
#   pod compose up
#   pod compose up --build
#   pod compose down
#   pod compose restart
#   pod compose ps
#   pod compose logs
#
# Containers:
#   pod container start <id>
#   pod container stop <id>
#   pod container restart <id>
#   pod container logs <id>
#   pod container stats <id>
export def pod [] {
  help pod
}
