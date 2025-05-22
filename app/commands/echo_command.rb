require_relative './command'

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
