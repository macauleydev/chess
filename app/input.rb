module Input
  def command_prompt(message, commands = {"" => ""})
    raise "There must be at least one available command." if commands.empty?
    choice = simple_prompt(message) until commands[choice]
    method(commands[choice]).call
  end
end

private

def simple_prompt(message)
  print message
  gets.chomp.upcase
end
