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
