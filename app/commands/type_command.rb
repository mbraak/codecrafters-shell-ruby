require_relative './command'

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
