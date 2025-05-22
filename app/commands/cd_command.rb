require_relative './command'

class CDCommand < Command
  def run
    if pathname.exist?
      Dir.chdir(pathname)
    else
      write_stdout("cd: #{pathname}: No such file or directory")
    end
  end

  private

  def pathname
    @pathname ||= if args.first.start_with?('~')
                    Pathname.new(ENV['HOME'])
                  else
                    Pathname.new(args.first)
                  end
  end
end
