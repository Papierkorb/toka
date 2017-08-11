require  "../src/toka"

# Demonstrates usage of an `Array(Int32)` target
# Run: `$ crystal samples/sequential.cr -- -n5 -n6`
#  Make sure to pass "--" to crystal    ^

# Also try passing `--help`!

class MyOptions # Create a container class
  Toka.mapping({ # Don't forget the opening braces!
    num: {
      type: Array(Int32),
      default: [ 1, 2, 3 ], # If none are passed, use these!
      # If no default is given, it falls back to an empty array!
    },
  })
end

# Now, create an instance:
opts = MyOptions.new # It will use `ARGV` by default!

#
puts "#{opts.num.join(" + ")} = #{opts.num.sum}"
