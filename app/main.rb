require 'fileutils'
require 'open3'

class SplitLine
  attr_reader :double_qoute, :escape, :input_line, :part, :parts, :previous_char, :single_quote

  def initialize(input_line)
    @input_line = input_line
    @double_qoute = false
    @escape = false
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
    if escape
      @part += char
      @escape = false
    else
      case char
      in ' '
        unless part.empty?
          parts << part
          @part = ''
        end
      in "'"
        @single_quote = true
      in '"'
        @double_qoute = true
      in '\\'
        @escape = true
      else
        @part += char
      end
    end
  end

  def handle_char_in_single_quote(char)
    if char == "'"
      @single_quote = false
    else
      @part += char
    end
  end

  def handle_char_in_double_quote(char)
    if escape
      @part += '\\' unless '\\$"'.include?(char)
      @part += char
      @escape = false
    else
      case char
      in '"'
        @double_qoute = false
      in '\\'
        @escape = true
      else
        @part += char
      end
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
  attr_reader :args, :command, :context, :output

  def initialize(args:, command:, context:, output:)
    @args = args
    @command = command
    @context = context
    @output = output
  end

  def run; end

  def write_stdout(line)
    output.write_stdout(line)
  end
end

class CDCommand < Command
  def run
    if pathname.exist?
      Dir.chdir(pathname)
    else
      write_stdout("cd: #{pathname}: No such file or directory")
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
    write_stdout(line)
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
    Open3.popen3(command, *args) do |_stdin, stdout, stderr, _wait_thr|
      stderr_output = stderr.read
      stdout_output = stdout.read

      output.write_stderr(stderr_output)
      output.write_stdout(stdout_output)
    end
  end
end

class ExitCommand < Command
  def run
    context.exit_repl
  end
end

class PwdCommand < Command
  def run
    write_stdout(Dir.getwd)
  end
end

class TypeCommand < Command
  def run
    write_stdout(builtin_result || program_result || not_found_result)
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

class StandardOutput
  def write_stdout(line)
    puts(line) unless line.empty?
  end

  def write_stderr(line)
    puts(line) unless line.empty?
  end

  def touch; end
end

class RedirectOutput < StandardOutput
  attr_reader :append, :file_name

  def initialize(append:, file_name:)
    super()

    @append = append
    @file_name = file_name
  end

  def touch
    FileUtils.touch(file_name)
  end

  protected

  def write_to_file(line)
    mode = append ? 'a' : 'w'

    file_contents = File.read(file_name)

    line = "\n#{line}" if append && !file_contents.empty? && !file_contents.end_with?("\n")

    file = File.new(file_name, mode)
    file.write(line)
    file.close
  end
end

class RedirectStdoutOutput < RedirectOutput
  def write_stdout(line)
    write_to_file(line)
  end
end

class RedirectStderrOutput < RedirectOutput
  def write_stderr(line)
    write_to_file(line)
  end
end

class ParseRedirectArgs
  attr_reader :args

  def initialize(args)
    @args = args
    @parsed = false
  end

  def parsed_args
    @parsed_args ||= begin
      parse_once

      if redirect_symbol.nil?
        args
      else
        args[0..-3]
      end
    end
  end

  def output
    parse_once
    @output
  end

  private

  def parse_once
    return if @parsed

    parse
    @parsed = true
  end

  def parse
    @output = case redirect_number
              in '1'
                RedirectStdoutOutput.new(append: append?, file_name: args[-1])
              in '2'
                RedirectStderrOutput.new(append: append?, file_name: args[-1])
              else
                StandardOutput.new
              end
  end

  def redirect_symbol
    @redirect_symbol ||= (args[-2] if args.length >= 3 && valid_redirect_symbol?(args[-2]))
  end

  def append?
    !redirect_symbol.nil? && redirect_symbol.end_with?('>>')
  end

  def valid_redirect_symbol?(symbol)
    return false unless symbol[-1] == '>'

    case symbol.length
    in 1
      true
    in 2
      %w[1 2 >].include?(symbol[0])
    in 3
      %w[1 2].include?(symbol[0]) && symbol[1] == '>'
    end
  end

  def redirect_number
    @redirect_number ||= if redirect_symbol.nil?
                           nil
                         elsif redirect_symbol.length == 1 || redirect_symbol[0] == '>'
                           '1'
                         else
                           redirect_symbol[0]
                         end
  end
end

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

    parse_redirect = ParseRedirectArgs.new(args)

    RunCommand.new(
      args: parse_redirect.parsed_args,
      command:,
      context:,
      output: parse_redirect.output
    ).run
  end

  def read
    input_line = gets

    if input_line.nil?
      [nil, nil]
    else
      SplitLine.new(input_line).run
    end
  end

  def parse_redirect(args); end
end

shell = Shell.new
shell.run
exit(shell.context.exit_code)
