class RedirectStdoutOutput < RedirectOutput
  def write_stdout(line)
    write_to_file(line)
  end
end
