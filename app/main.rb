loop do
  $stdout.write('$ ')
  command, *args = gets.chomp.split(' ')

  if command == 'exit' && args.first == '0'
    exit 0
  else
    puts("#{command}: command not found")
  end
end
