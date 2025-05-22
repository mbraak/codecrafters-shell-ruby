class RedirectStderrOutput < RedirectOutput
  def write_stderr(line)
    write_to_file(line)
  end
end
