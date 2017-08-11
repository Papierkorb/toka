require  "../src/toka"

# Demonstrates how to make use of the generated help page
# Run: `$ crystal samples/help.cr   -- --name=Foo --verbose`
#  Make sure to pass "--" to crystal ^

class MyOptions # Create a container class
  Toka.mapping({ # Don't forget the opening braces!
    name: {
      type: String,
      description: "Whom to greet",
      value_name: "NAME",
    },
    last_name: {
      type: String?,
      description: "Last name, if any",
      value_name: "NAME",
    },
    verbose: {
      type: Bool,
      # default: false, # Bools default to "false"
      description: "Increase verbosity",
      category: "Logging" # You can have categories too!
    },
    log_file: {
      type: String?,
      description: "Logfile to use",
      category: "Logging"
    }
  }, { # Now we further customize the help output
    banner: "Toka help example",
    footer: "\nLicensed under the MIT license"
  })
end

# Now, create an instance:
opts = MyOptions.new

# And access the fields.
puts "Hello, #{opts.name} #{opts.last_name}!"
puts "Now add --help"

pp opts.verbose, opts.log_file
