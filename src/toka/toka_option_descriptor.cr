module Toka
  # Run-time structure to describe all options supported by a class.
  class OptionDescriptor
    getter options : Array(Option)
    getter banner : String
    getter footer : String?

    def initialize(@banner, @footer, @options)
    end

    delegate :[], size, first, last, each, to: @options

    def_equals_and_hash @options, @banner, @footer
  end
end
