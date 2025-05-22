require_relative './command'

class PwdCommand < Command
  def run
    write_stdout(Dir.getwd)
  end
end
