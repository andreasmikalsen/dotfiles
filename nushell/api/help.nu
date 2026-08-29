# Manage API collections, environments, authentication, and saved requests.
#
# Collections:
#   api collection init <name>    Create a new collection
#   api collections               List available collections
#   api collection use <name>     Select a collection
#
# Environments:
#   api env list                  List environments
#   api env use <name>            Select an environment
#
# Requests:
#   api list                      List saved requests
#   api show <request>            Show a request definition
#   api run <request>             Execute a request
#
# Authentication:
#   api auth login [name]         Authenticate and cache an OAuth token
#   api auth status               Show cached authentication state
#   api auth clear                Clear cached OAuth tokens
#
# Examples:
#   api collection use work-api
#   api env use dev
#   api run users/get-user
#   api run users/get-user | get body
#
# Private API workspace:
#   nuapi
export def api [] {
  help api
}
