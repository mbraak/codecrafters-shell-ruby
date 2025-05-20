class SplitLine
  attr_reader :double_qoute, :input_line, :part, :parts, :previous_char, :single_quote

  def initialize(input_line)
    @input_line = input_line
    @double_qoute = false
    @parts = []
    @part = ''
    @previous_char = nil
    @single_quote = false
  end

  def run
    input_line.chomp.chars.each do |char|
      if single_quote
        handle_char_in_single_quote(char)
      elsif double_qoute
        handle_char_in_double_quote(char)
      else
        handle_char(char)
      end

      @previous_char = char
    end

    parts << part unless part.empty?

    [parts.first, parts[1..]]
  end

  private

  def handle_char(char)
    if previous_char == '\\'
      @part += char
    else
      case char
      in ' '
        unless part.empty?
          parts << part
          @part = ''
        end
      in "'" if part.empty?
        if previous_char == "'"
          @part = parts[-1]
          @parts.pop
        end

        @single_quote = true
      in '"' if part.empty?
        if previous_char == '"'
          @part = parts[-1]
          @parts.pop
        end

        @double_qoute = true
      in '\\'
        # Do nothing
      else
        @part += char
      end
    end
  end

  def handle_char_in_single_quote(char)
    if char == "'"
      parts << part
      @part = ''
      @single_quote = false
    else
      @part += char
    end
  end

  def handle_char_in_double_quote(char)
    if char == '"'
      parts << part
      @part = ''
      @double_qoute = false
    else
      @part += char
    end
  end
end

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

class CDCommand < Command
  def run
    if pathname.exist?
      Dir.chdir(pathname)
    else
      puts("cd: #{pathname}: No such file or directory")
    end
  end

  private

  def pathname
    @pathname ||= if args.first.start_with?('~')
                    Pathname.new(ENV['HOME'])
                  else
                    Pathname.new(args.first)
                  end
  end
end

class EchoCommand < Command
  def run
    puts(line)
  end

  private

  def line
    args
      .join(' ')
      .strip
  end
end

class ExecutableCommand < Command
  def run
    system(command, *args)
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
  def run
    puts(builtin_result || program_result || not_found_result)
  end

  private

  def command_arg
    args.first
  end

  def builtin?
    Builtins.builtin?(command_arg)
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

class Builtins
  COMMANDS = {
    cd: CDCommand,
    echo: EchoCommand,
    exit: ExitCommand,
    pwd: PwdCommand,
    type: TypeCommand
  }.freeze

  def self.get_command_class(command_name)
    COMMANDS[command_name.to_sym]
  end

  def self.builtin?(command_name)
    COMMANDS.key?(command_name.to_sym)
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
      SplitLine.new(input_line).run
    end
  end

  def parse(command, args)
    try_run_builtin_command(command, args) || try_run_executable(command, args) || command_not_found(command)
  end

  def try_run_builtin_command(command, args)
    command_class = Builtins.get_command_class(command)

    return false unless command_class

    command_class.new(args:, command:, context:).run
    true
  end

  def try_run_executable(command, args)
    command_path = context.find_command_path(command)

    return false unless command_path

    ExecutableCommand.new(args:, command:, context:).run
    true
  end

  def command_not_found(command)
    puts("#{command}: command not found")
  end
end

shell = Shell.new
shell.run
exit(shell.context.exit_code)
