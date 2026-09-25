# Terminal observability dashboards backed by Prometheus and nu-db.
#
# Environment:
#   obs env list
#   obs env use <name>
#   obs status
#
# Prometheus:
#   obs check prometheus
#   obs query prometheus '<promql>'
#
# SQL:
#   obs query sql <database> <query-file>
#   obs query sql <database> <query-file> --environment prod
#
# Dashboards:
#   obs dashboard
#   obs dashboard overview
#   obs dashboard overview --once
export def obs [] { help obs }
