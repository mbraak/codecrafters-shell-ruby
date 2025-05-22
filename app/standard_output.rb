class StandardOutput
  def write_stdout(line)
    puts(line) unless line.empty?
  end

  def write_stderr(line)
    puts(line) unless line.empty?
  end

  def touch; end
end
