# Podman + Compose workflow for Nushell.
#
# TUI:
#   pod tui
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
#
# The compose commands look for:
#   docker-compose.yml
#   docker-compose.yaml
#   compose.yml
#   compose.yaml
#
# starting in the current directory and walking upward.
export def pod [] {
  help pod
}
