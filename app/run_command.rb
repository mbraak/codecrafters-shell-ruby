require_relative './builtins'
require_relative './commands/executable_command'

class RunCommand
  attr_reader :args, :command, :context, :output

  def initialize(args:, command:, context:, output:)
    @args = args
    @command = command
    @context = context
    @output = output
  end

  def run
    output.touch

    try_run_builtin_command || try_run_executable || command_not_found
  end

  private

  def try_run_builtin_command
    command_class = Builtins.get_command_class(command)

    return false unless command_class

    command_class.new(args:, command:, context:, output:).run
    true
  end

  def try_run_executable
    command_path = context.find_command_path(command)

    return false unless command_path

    ExecutableCommand.new(args:, command:, context:, output:).run
    true
  end

  def command_not_found
    output.write_stdout("#{command}: command not found")
  end
end
