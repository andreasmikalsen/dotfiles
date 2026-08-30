# Manage private database connections from Nushell.
#
# Database selection:
#   db list                       List configured databases
#   db init <name>                Create a PostgreSQL local/test/prod skeleton
#   db use <name>                 Select a database
#   db show                       Show the active connection without secrets
#   db status                     Show current selection
#
# Environments:
#   db env list                   List local/test/prod environments
#   db env use <name>             Select an environment
#
# Authentication:
#   db auth status                Show auth mode and Azure account information
#
# Connections:
#   db connect                    Open psql or redis-cli for the active database
#   db query <sql>                Run a PostgreSQL query and return Nu records
#   db exec <sql>                 Run PostgreSQL SQL and return raw output
#   db tui                        Open active PostgreSQL database in Rainfrog
#
# Examples:
#   db use orders
#   db env use test
#   db auth status
#   db connect
#   db query "select id, email from users limit 10" | where email =~ "@company"
#   db query "select * from orders" | get id
#
# Private workspace:
#   %LOCALAPPDATA%\nu-db
export def db [] {
  help db
}
