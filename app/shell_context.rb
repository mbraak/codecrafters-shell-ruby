class ShellContext
  attr_reader :continue, :exit_code

  def initialize
    @continue = true
    @exit_code = 0
  end

  def exit_repl
    @continue = false
  end

  def find_command_path(command)
    paths.find do |path|
      path.join(command).exist?
    end
  end

  def paths
    @paths ||= ENV['PATH'].split(':').map { Pathname.new(_1) }
  end
end
