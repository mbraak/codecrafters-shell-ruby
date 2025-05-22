require_relative './standard_output'
require_relative './redirect_output'
require_relative './redirect_stderr_output'
require_relative './redirect_stdout_output'

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
