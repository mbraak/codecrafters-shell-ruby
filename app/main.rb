class Shell
  attr_reader :continue, :exit_code

  def initialize
    @continue = true
    @exit_code = 0
  end

  def run
    read_eval_print while continue
  end

  private

  def read_eval_print
    $stdout.write('$ ')
    command, args = read
    return exit_repl if command.nil?

    parse(command, args)
  end

  def exit_repl
    @continue = false
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
    when 'echo'
      handle_echo(args)
    when 'exit'
      exit_repl
    when 'type'
      handle_type(args)
    else
      puts("#{command}: command not found")
    end
  end

  def handle_echo(args)
    puts(args.join(' '))
  end

  def handle_type(args)
    command = args[0]

    if %w[echo exit type].include?(command)
      puts("#{command} is a shell builtin")
    elsif !command.nil?
      puts("#{command}: not found")
    end
  end
end

shell = Shell.new
shell.run
exit(shell.exit_code)
