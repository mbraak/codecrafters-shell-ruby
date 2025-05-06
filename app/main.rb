loop do
  $stdout.write('$ ')
  command, *_args = gets.chomp.split(' ')
  puts("#{command}: command not found")
end
