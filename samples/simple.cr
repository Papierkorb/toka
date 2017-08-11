require  "../src/toka"

# Demonstrates a really simple option parser.
# Run: `$ crystal samples/simple.cr -- --name=Foo --verbose`
#  Make sure to pass "--" to crystal ^

# Also try passing `--help`!

class MyOptions # Create a container class
  Toka.mapping({ # Don't forget the opening braces!
    name: String, # Mandatory option "--name"
    last_name: String?, # Optional option "--last-name"
    verbose: Bool, # "--verbose" defaults to `false`
  })
end

# Now, create an instance:
opts = MyOptions.new # It will use `ARGV` by default!

# And access the fields.
puts "Hello, #{opts.name} #{opts.last_name}"

# Bool-type fields have an question-mark getter too!
puts "I'll stay quiet!" if opts.verbose?

# Print positional options is trivial:
puts "Positional options: #{opts.positional_options}"
