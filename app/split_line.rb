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
