require 'reline'
require_relative './shell_context'
require_relative './split_line'
require_relative './parse_redirect_args'
require_relative './run_command'

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
    Reline.completion_proc = proc { |_word|
      %w[echo exit]
    }

    input_line = Reline.readline('$ ', true)

    if input_line.nil?
      [nil, nil]
    else
      SplitLine.new(input_line).run
    end
  end
end
