module Toka
  # Run-time structure to describe an available option.
  class Option
    getter name : String
    getter long_names : Array(String)
    getter short_names : Array(Char)
    getter description : String?
    getter value_name : String
    getter? has_value : Bool
    getter category : String?

    def initialize(@name, @long_names, @short_names, @value_name, @description, @category, @has_value)
    end

    def_equals_and_hash @name, @long_names, @short_names, @description, @value_name, @has_value, @category
  end
end
