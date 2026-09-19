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
#   pod container start <name>
#   pod container stop <name>
#   pod container restart <name>
#   pod container logs <name>
#   pod container stats <name>
export def pod [] {
  help pod
}
