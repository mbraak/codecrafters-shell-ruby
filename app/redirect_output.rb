require 'fileutils'

class RedirectOutput < StandardOutput
  attr_reader :append, :file_name

  def initialize(append:, file_name:)
    super()

    @append = append
    @file_name = file_name
  end

  def touch
    FileUtils.touch(file_name)
  end

  protected

  def write_to_file(line)
    mode = append ? 'a' : 'w'

    file_contents = File.read(file_name)

    line = "\n#{line}" if append && !file_contents.empty? && !file_contents.end_with?("\n")

    file = File.new(file_name, mode)
    file.write(line)
    file.close
  end
end
