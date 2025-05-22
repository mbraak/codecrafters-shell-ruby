require_relative './commands/cd_command'
require_relative './commands/echo_command'
require_relative './commands/exit_command'
require_relative './commands/pwd_command'
require_relative './commands/type_command'

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
