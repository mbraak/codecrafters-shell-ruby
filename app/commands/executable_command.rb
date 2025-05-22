require 'open3'
require_relative './command'

class ExecutableCommand < Command
  def run
    Open3.popen3(command, *args) do |_stdin, stdout, stderr, _wait_thr|
      stderr_output = stderr.read
      stdout_output = stdout.read

      output.write_stderr(stderr_output)
      output.write_stdout(stdout_output)
    end
  end
end
