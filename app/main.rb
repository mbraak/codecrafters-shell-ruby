class ShellContext
  attr_reader :continue, :exit_code

  def initialize
    @continue = true
    @exit_code = 0
  end

  def exit_repl
    @continue = false
  end

  def find_command_path(command)
    paths.find do |path|
      path.join(command).exist?
    end
  end

  def paths
    @paths ||= ENV['PATH'].split(':').map { Pathname.new(_1) }
  end
end

class Command
  attr_reader :args, :command, :context

  def initialize(args:, command:, context:)
    @args = args
    @command = command
    @context = context
  end

  def run; end
end

class EchoCommand < Command
  def run
    puts(args.join(' '))
  end
end

class ExecutableCommand < Command
  def run
    args_string = args.join(' ')
    command_string = "#{command} #{args_string}"
    system(command_string)
  end
end

class ExitCommand < Command
  def run
    context.exit_repl
  end
end

class PwdCommand < Command
  def run
    puts(Dir.getwd)
  end
end

class TypeCommand < Command
  BUILTIN_COMMANDS = %w[echo exit pwd type].freeze

  def run
    puts(builtin_result || program_result || not_found_result)
  end

  private

  def command_arg
    args[0]
  end

  def builtin?
    BUILTIN_COMMANDS.include?(command_arg)
  end

  def command_path
    @command_path = context.find_command_path(command_arg) unless defined? @command_path
    @command_path
  end

  def builtin_result
    "#{command_arg} is a shell builtin" if builtin?
  end

  def program_result
    "#{command_arg} is #{command_path}/#{command_arg}" if command_path
  end

  def not_found_result
    "#{command_arg}: not found"
  end
end

class Shell
  attr_reader :context

  def initialize
    @context = ShellContext.new
  end

  def run
    read_eval_print while context.continue
  end

  private

  def read_eval_print
    $stdout.write('$ ')
    command, args = read
    return context.exit_repl if command.nil?

    parse(command, args)
  end

  def read
    input_line = gets

    if input_line.nil?
      [nil, nil]
    else
      command, *args = input_line.chomp.split(' ')
      [command, args]
    end
  end

  def parse(command, args)
    case command
    in 'echo'
      EchoCommand.new(args:, command:, context:).run
    in 'exit'
      ExitCommand.new(args:, command:, context:).run
    in 'pwd'
      PwdCommand.new(args:, command:, context:).run
    in 'type'
      TypeCommand.new(args:, command:, context:).run
    in _ if context.find_command_path(command)
      ExecutableCommand.new(args:, command:, context:).run
    else
      puts("#{command}: command not found")
    end
  end
end

shell = Shell.new
shell.run
exit(shell.context.exit_code)
