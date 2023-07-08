module Toka
  # Built-in parameter-value converters.  Used by a `Toka.mapping` parser to
  # parse the given string.
  module Converter
    # Converter for `String`
    module String
      def self.read(input : ::String) : ::String?
        input
      end
    end

    # Converter for `Bool`
    module Bool
      def self.read(input : ::String) : ::Bool?
        case input.downcase
        when "true", "t", "yes", "y"
          true
        when "false", "f", "no", "n"
          false
        else
          nil
        end
      end
    end

    # Converter for `URI`
    module URI
      def self.read(input : ::String) : ::URI?
        ::URI.parse(input)
      end
    end

    {% for meth, type in {i8: Int8, i16: Int16, i32: Int32, i64: Int64, u8: UInt8, u16: UInt16, u32: UInt32, u64: UInt64, f32: Float32, f64: Float64} %}
      # Converter for `{{ type }}`
      module {{ type }}
        def self.read(input : ::String) : ::{{ type }}?
          input.to_{{ meth }}?
        end
      end
    {% end %}
  end
end
