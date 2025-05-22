require_relative './command'

class ExitCommand < Command
  def run
    context.exit_repl
  end
end
