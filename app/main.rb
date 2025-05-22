require_relative './shell'

shell = Shell.new
shell.run
exit(shell.context.exit_code)
