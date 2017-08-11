require  "../src/toka"

# Demonstrates how to build an user-friendly error output.
# Run: `$ crystal samples/error_handling.cr

class MyOptions # Create a container class
  Toka.mapping({ # Don't forget the opening braces!
    name: {
      type: String,
      description: "Whom to greet",
    },
    count: {
      type: Int32,
      description: "Times to greet",
      default: 1,
    },
  })
end

# Helper methods to output something pretty
def print_error_pointer(position)
  pointer = "^~~~~".colorize(:red).to_s

  # Calculate the position on screen of the error position
  justification = ARGV.map(&.size)[0...position].sum + 1

  # Guess how the arguments were written into the shell
  puts "  #{ARGV.join(" ").colorize(:yellow)}"
  puts "  #{" " * justification}#{pointer}"
end

def print_description(option)
  puts
  puts "Description:"
  puts "  #{option.description.to_s.gsub("\n", "\n  ")}"
end

begin
  opts = MyOptions.new # It will use `ARGV` by default!
  opts.count.times{ puts "Hello, #{opts.name}!" }

  # Handle errors with some user-friendly-ish output
rescue err : Toka::UnknownOptionError | Toka::ParseError
  print_error_pointer err.position if err.responds_to?(:position)
  puts "#{err.class}: #{err.message}"
  print_description(err.option) if err.responds_to?(:option)

rescue err : Toka::MissingOptionError
  option = err.option # The error supplies us the errored option!
  puts "Missing required option #{option.name.inspect}"
  puts "  Set it like this: --#{option.long_names.first}=#{option.value_name}"
  print_description(option)
end
