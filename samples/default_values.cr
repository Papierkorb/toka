require "../src/toka"

# Demonstrates the use of default values
# Run: `$ crystal samples/default_values.cr -- --name=Foo --verbose`
#  Make sure to pass "--" to crystal        ^

class MyOptions  # Create a container class
  Toka.mapping({ # Don't forget the opening braces!
    name: {
      type:    String,
      default: "World", # Greet the World by default
    },
    last_name: String?, # You can mix complex with simple declarations.  Great for hacking!
  })
end

# Now, create an instance:
opts = MyOptions.new # It will use `ARGV` by default!

# And access the fields.
puts "Hello, #{opts.name} #{opts.last_name}!"
