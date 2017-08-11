require  "../src/toka"

# Demonstrates the use of a verifier.
# Run: `$ crystal samples/verification.cr -- --name=Bob --age=15`
#  Make sure to pass "--" to crystal      ^

class MyOptions
  Toka.mapping({
    name: {
      type: String,
      verifier: ->(x : String){ x == "Bob" } # Only accepts "Bob" as input
    },
    age: {
      type: Int32, # Simple age restriction with additional message:
      verifier: ->(x : Int32){ x >= 18 || "Must be an adult" }
    }
  })
end

# Now, create an instance:
opts = MyOptions.new # It will use `ARGV` by default!

# And access the fields.
puts "#{opts.name} is #{opts.age}"
