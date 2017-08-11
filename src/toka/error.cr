module Toka
  # Base error class of `Toka`.
  class Error < Exception
  end

  # Generic parser error, providing the `#option` that was tried to match.
  class ParseError < Error
    getter arguments : Array(String)
    getter position : Int32
    getter option : ::Toka::Option

    def initialize(message, @arguments, @position, @option)
      super(message)
    end
  end

  # Raised when an unknown option is encountered.
  class UnknownOptionError < Error
    getter arguments : Array(String)
    getter position : Int32
    getter name : String

    def initialize(message, @arguments, @position, @name)
      super(message)
    end
  end

  # Raised when a converter returns `nil`.
  class ConversionError < ParseError
  end

  # Raised when a verifier signaled an error.
  class VerificationError < ParseError
    getter verifier_message : String?

    def initialize(message, arguments, position, option, @verifier_message)
      super(message, arguments, position, option)
    end
  end

  # Raised when a required option was not found.
  class MissingOptionError < Error
    getter arguments : Array(String)
    getter option : ::Toka::Option

    def initialize(message, @arguments, @option)
      super(message)
    end
  end

  # Raised when an option requiring a value was not passed one.
  class MissingValueError < ParseError
  end

  # Raised when an option of type `Hash` is accessed with a key, but without a
  # value.
  class HashValueMissingError < ParseError
  end
end
