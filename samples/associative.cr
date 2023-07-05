require "../src/toka"

# Demonstrates usage of an `Hash(String, Int32)` target
# Run: `$ crystal samples/associative.cr -- -mOne=1 -mTwo=2`
#  Make sure to pass "--" to crystal     ^

class MyOptions  # Create a container class
  Toka.mapping({ # Don't forget the opening braces!
    map: {
      type: Hash(String, Int32), # Also try other types of keys and values
      default: { "Three" => 3 }, # If none are passed, use these!
      # If no default is given, it falls back to an empty hash!
    },
  })
end

# Now, create an instance:
opts = MyOptions.new # It will use `ARGV` by default!

#
# puts "#{opts.num.join(" + ")} = #{opts.num.sum}"
opts.map.each do |key, value|
  puts "#{key.inspect} => #{value.inspect}"
end
