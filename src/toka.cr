require "colorize" # For HelpPageRenderer
require "uri"      # For the built-in converter
require "./toka/*"

module Toka
  # Creates an option parser.  Options are defined in *mapping pattern* fashion,
  # much like `JSON.mapping`.
  #
  # The macro takes two arguments, where both are `NamedTuple`s.  The first one
  # *options* are the options you want to recognize.  The second one *info*
  # contains additional configuration, mostly required to auto-generate a nice
  # `--help` page.
  #
  # ## Explanation of argument passing
  #
  # This just covers the common UNIX-style option-passing.  You can skip this if
  # you're familiar with it - `Toka` implements it!
  #
  # **Note**: Windows-style passing, using a leading slash (e.g. `/f`) instead
  # of dashes, are not supported.
  #
  # First, options are split word-wise (According to the program calling another
  # program, usually your shell).  A "word" may actually consist out of multiple
  # readable words separated by a space (" "), so don't get confused.
  #
  # Second, there are two kinds of options: Switches, and positional options.
  # The first kind are those which are "named", and are accessed directly by
  # one of their names.  Positional options are not: All options which do not
  # look like an option ("bare words") are positional options.
  #
  # Example: `wc -l foo` This invokes the `wc` utility, passing the `-l` switch,
  # and the `foo` positional option.
  #
  # ### Long- and short-options
  #
  # Many options have a long-name, and a short-name. (They may have further
  # aliases).  Long-names are longer than their short-name counterparts.  They
  # are distinguished by the leading count of dashes: Two ("--") for a
  # long-name, and one ("-") for a short-name.
  #
  # Long-names for an option are usually whole words, but can span multiple
  # words.  It is common to separate words using a single dash:
  # `--street-number`.  It is not possible to define multiple long-names at
  # once.  Sometimes long-names are case-sensitive, other times they're not.
  # `Toka` implements long-names case-sensitively.
  #
  # Short-names are commonly one character only.  You can combine multiple
  # short-name switches into a single word: `-abc` will flip the switches
  # for `a`, `b` and `c`.  This is equivalent to doing the following: `-a -b -c`.
  #
  # ### Value passing
  #
  # In many cases it's desirable to pass specific values to a switch for further
  # configuration.
  #
  # For long-names, the value can either follow in the same word by separating
  # the value from the long-name using an equal-sign ("="): `--foo=bar` would
  # pass the value "bar" to the "foo" switch.  If no equal-sign is found while
  # requiring a value, the following word is used: `--foo bar` is equivalent.
  #
  # For short-names, the value *immediately* follows the short option: `-fBar`
  # would pass "Bar" to the "f" switch.  This is a common source of confusion
  # and mistakes: Say we have the switch "a" not taking a value, and "b" taking
  # one.  Now, you want to invoke both, and pass a value to "b". So you write
  # `-ba foo` - And suddenly, you passed "a" to the "b" switch as value, and
  # "foo" is treated as positional option.  Correct is this: `-ab foo` - This
  # activates the "a" switch, and passes "foo" to the "b" switch.  You can also
  # combine non-value-taking with value-taking short-names into the same word:
  # `-abfoo` will activate "a", abd pass "foo" to "b".
  #
  # ### Cancelling option parsing
  #
  # Sometimes it may be useful to tell the option parser that some options are
  # to be treated as positional options.  There are two solutions to this:
  #
  # 1. Escape it by prepending a back-slash: `\--foo`
  # 2. Ignore everything following by stand-alone double-dash: `--foo -- --bar`
  #    will activate the "foo" switch, but pass "--bar" as positional option.
  #
  # ## Simple usage
  #
  # If you just want to parse some arguments quickly, right now, without messing
  # around much, and without reading any longer and longer sentences in the
  # documentation of `Toka` while thinking someone is messing with *you* right now,
  # here's an example:
  #
  # ```
  # class MyOptions         # Create a container class
  #   Toka.mapping({        # Don't forget the opening braces!
  #     name:      String,  # Mandatory option
  #     last_name: String?, # Optional option
  #     verbose:   Bool,    # Mandatory option
  #   })
  # end
  #
  # # Now, create an instance:
  # opts = MyOptions.new # It will use `ARGV` by default!
  #
  # # And access the fields.  Bool-type fields have an question-mark getter too!
  # puts "Hello, #{opts.name} #{opts.last_name}" if opts.verbose?
  # ```
  #
  # With this, the user can pass something like `--name Alice --no-verbose`, or
  # just `--help` (or `-h`) to print a help page.
  #
  # **Hint** You can find usage-examples in `samples/` !
  #
  # **Note**: The default help page renderer will `exit()` the process after
  # printing its output!
  #
  # For more, see the next section.
  #
  # ## Advanced usage
  #
  # `Toka` can do much more than that.  To adjust further settings, you can pass
  # a `NamedTuple` as value too!
  #
  # The settings tuple supports the following options:
  #
  # * `type` The type.  Examples: `String`, `Int32?`, `Array(String)`
  # * `nilable` If the type is optional ("nil-able").  You can also make the `type` nilable for the same effect.
  # * `default` The default value.
  # * `long` Allows to manually configure long-options.  Auto-generated from the name otherwise.
  # * `short` Allows to manually configure short-options.  Auto-generated otherwise.  Set to `false` to disable.
  # * `converter` Converter to use for the value.  See below.
  # * `value_converter` Alias for `converter`.
  # * `key_converter` Converter for the key to use for a `Hash` type.
  # * `verifier` Verifier for the value.  See below.
  # * `value_verifier` Alias for `verifier`.
  # * `key_verifier` Verifier for the key of a `Hash` type.
  # * `description` The human-readable description.  Can be multi-line.
  # * `value_name` Human-readable value name, shown next to the option name like: `--foo=HERE`
  # * `category` Human-readable category name, for grouping in the help page. Optional.
  #
  # **Note**: The `long` and `short` fields can take a single string, or an
  # array of strings.  Do *not* prepend dashes yourself, `Toka` will do that!
  #
  # The *info* argument allows the following options:
  #
  # * `banner` The banner string.  Displayed as first line(s) in the help page.
  # * `footer` The footer string.  Displayed as last line(s) in the help page.
  # * `help` If to auto-generate the `--help`/`-h` option.  Defaults to `true`.
  # * `colors` If the help page shall be colorized.  Defaults to `true`.
  #
  # With this, a more fully-featured example, based on the one above:
  #
  # ```
  # class MyOptions
  #   Toka.mapping({ # Still don't forget the opening braces!
  #     name: {
  #       type:        String,          # Still a String
  #       default:     "World",         # But greet the World if none was given
  #       description: "Whom to greet", # For the help page
  #       value_name:  "NAME",          # Same ^
  #     },
  #     last_name: {
  #       type: String?,
  #       # nilable: true, # Alternatively, write `type: String` and this
  #     },
  #     verbose: {
  #       type: Bool?, # Trick to detect explicit activation and deactivation
  #     },
  #   })
  # end
  #
  # # Now, create an instance:
  # opts = MyOptions.new # It will use `ARGV` by default!
  #
  # # And access the fields.  Bool-type fields have an question-mark getter too!
  # puts "Hello, #{opts.name} #{opts.last_name}" if opts.verbose?
  # ```
  #
  # ## Positional options
  #
  # All positional options are collected into a the `#positional_options` array.
  #
  # This includes bare words, argument-looking words with a leading back-slash,
  # and everything after a stand-alone double-dash "argument":
  #
  # The line `--one \--two three -- --four -five six` would activate the "one"
  # switch, and collect the positional options like this:
  # `[ "--two", "three", "--four", "-five", "six" ]`.
  #
  # ## Converters
  #
  # A converter is a module or class, responding to `.read(raw_value : String) : T?`.
  # On success, this method returns an instance of `T`, otherwise, it can
  # either return `nil` to prompt a default error message, or raise a more
  # descriptive one itself.
  #
  # ```
  # Sample only!  Please do more error checking in your converters!
  # module IpV4Converter
  #   def self.read(input : String) : Int32? # You can also just write `Int32`
  #     input.split(".", 4).map(&.to_u32).reduce(0u32) {|x, a| (a << 8) | x}
  #   end
  # end
  #
  # class MyOptions
  #   Toka.mapping({
  #     addr: {                     # Reacts to `--addr`
  #       type:      UInt32,        # The result will be a UInt32
  #       converter: IpV4Converter, # And we want to use this converter
  #     },
  #   })
  # end
  # ```
  #
  # ## Input verification
  #
  # It is possible to verify input data before it's being used.  To do this,
  # pass a `Proc` through the `verifier` (or `value_verifier`) field setting.
  # For the key of a `Hash` type, `key_verifier` is what you're looking for.
  #
  # This `Proc` gets passed the already converted value, and is then expected to
  # return either a `false` or a `String` to signal an error, or anything else
  # to signal success.
  #
  # If the verifier responds with a `false`, the user will receive a generic
  # `Toka::VerificationError`.  If the response is a `String`, it will be
  # appeneded to its message for further context.
  #
  # ```
  # class MyOptions
  #   Toka.mapping({
  #     name: {
  #       type:     String, #  vvvvvv Type is required for Crystal!
  #       verifier: ->(x : String) { x == "Bob" }, # Only accepts "Bob" as input
  #     },
  #     age: {
  #       type:     Int32, # Simple age restriction with additional message:
  #       verifier: ->(x : Int32) { x >= 18 || "Must be an adult" },
  #     },
  #   })
  # end
  # ```
  #
  # **Note**: The verifier can be anything that responds to `#call()`, behaving
  # like a `Proc`.  You could also have a module which responds to
  # `self.call(x)`, and pass in that module.
  #
  # ## Error handling
  #
  # When an error is encountered while parsing the input, a sub-class of
  # `Toka::Error` is raised.  All error classes provide additional data to
  # the error handler by carrying additional fields, next to the standard
  # message.
  #
  # **Note**: A converter or verifier raising a custom error are not handled
  # by Toka.  They're passed through.  Albeit losing the additional information
  # Toka errors provide, this is supported.
  #
  # ## Sequential and associative options
  #
  # By using `Array(T)` or `Hash(K, V)` as type, you allow the user to pass in
  # multiple values for a single option.  They're added in the order they're
  # read: The left-most value will be the first one to be added, and so on.
  #
  # For `Array(T)`, the user has to repeat the option for each element to be
  # added. If you have an option called `many` of type `Array(String)`, the user
  # passes `--many one --many two --many three` to generate
  # `[ "one", "two", "three" ]`.
  #
  # For `Hash(K, V)`, the user repeats the option for each key-value pair,
  # separating the key from the value using an equal-sign ("=") like this:
  # `--many foo=bar --many one=two` will generate
  # `{ "foo" => "bar", "one" => "two" }`.
  #
  # You're not restricted to using `String`.  You can use whichever type you
  # want.  The built-in ones will just work, for others, use a custom converter.
  # Converters will be invoked with one value each, and thus work out of the box.
  #
  # **Note**: These containers are not nil-able.  Instead, you'll get an empty
  # container.  You can still pass a default one though!
  #
  # **Note**: Nested containers are *not* supported.
  #
  # ```
  # class MyOptions
  #   Toka.mapping({
  #     name:    Array(String), # Simple usage
  #     ints:    Array(Int32),  # Works too
  #     streets: {
  #       type:    Array(String),
  #       default: ["Foo st", "Bar st"], # Will only be used if none are given.
  #     },
  #     birthday: {
  #       type:            Hash(String, Time), # Associative data
  #       key_converter:   TitelizeName,       # Converter for the key
  #       value_converter: TimeConverter,      # Converter for the value
  #       # converter: TimeConverter, # Alias, equivalent to the one above
  #     },
  #   })
  # end
  # ```
  #
  # **Note**: The parser is restricted to `Array` and `Hash`.  You can't use other
  # generic types.
  #
  # ## Boolean behaviour
  #
  # `Bool` is somewhat special.  Switches of this type don't require a value.
  # If the user wants to explicitly set one, `--switch=false` has to be used.
  # A following `true` or `false` will **not** be detected.
  #
  # Further, a `Bool` switch automatically gets two versions:  The active
  # version, and the inactive one.  The long-name for the inactive one is the
  # active name with a "no-" prepended: `--verbose` gets turned into
  # `--no-verbose`.  For the short-name, the existing short-names are taken and,
  # if no collisions are detected, inversed by uppercasing the character.  This
  # also works, if the short-name was auto-generated in the first place.  In
  # our example, the `--verbose` switch would be assigned `-v` as short switch,
  # and it would be uppercased to negate: From `-v` to `-V`.
  #
  # As already noted, the user has to follow a value immediately if one is
  # passed.  Only the long-name supports this, the short-name **does not**.
  # So, this will work: `--verbose=true`, but this **will not**: `-vtrue`.
  #
  # The following inputs will be turned into `true`: `true`, `yes`, `t` and `y`.
  # For `false`: `false`, `no`, `f`, `n`.  Other inputs will **raise an error**.
  #
  # ### Bool in containers
  #
  # It's possible to mix containers with Bool, like `Array(Bool)` or
  # `Hash(String, Bool)`.  No automatic (de-)activation switch is generated
  # for these cases, meaning the user has to explicitly set the value.
  #
  # Sample for an array: `-ayes -ayes -ano` gives `[ true, true, false ]`.
  # Hash sample: `-afoo=yes -abar=no` gives `{ "foo" => true, "bar" => false }`.
  #
  # ## Generation behaviour
  #
  # The macro tries to do as much for you as possible, so here's what's possible:
  #
  # * The long-name is generated from the dasherized name: `foo_bar: String` will be turned into `--foo-bar`.
  # * The short-names are generated from the long-name, prefering the first character of each word of each
  #   long-name, and using any following characters afterwards.  Done until an unique one is found, or none at all.
  # * `Bool` type options get both a getter with question-mark and one without: `#verbose` is the same as `#verbose?`
  # * A `--help` page is generated.  Upon activation through the user, the process is exited!
  macro mapping(options, info = {banner: nil, footer: nil, help: true, colors: true})
    {% short_names = [] of String
       opt_index = 0
       short_names << 'h' if info[:help] != false
       help_colors = info[:colors] != false %}

    {% for k, v in options %}
      {% # Prepare the option configuration
       v = v.is_a?(NamedTupleLiteral) ? v : {type: v}
       type = v[:type] # Resolve wanted type
       type = type.is_a?(Path) ? type.resolve : type

       # Read desired configuration or use default values
       long = v[:long] || [k.stringify.gsub(/_/, "-")]
       short = v[:short] == false ? false : (v[:short] || [] of String)
       long = [long] if long.is_a? String
       short = [short] if short.is_a? String
       nilable = v[:nilable]
       short_names = short_names + short unless short == false
       value_name = v[:value_name] || "VALUE"

       key_type = nil
       value_type = type
       nonnil_type = type
       has_default = v.keys.map(&.stringify).includes?("default")
       default = v[:default]

       if type.is_a?(Generic) && type.name.resolve == ::Union
         types = type.type_vars.map { |x| x.is_a?(Path) ? x.resolve : x }

         if types.includes?(Nil)
           nilable = true
           nonnils = types.reject(&.==(Nil))

           if nonnils.size == 1
             nonnil_type = nonnils.first
           else
             nonnil_type = Union.new(nonnils)
           end

           value_type = nonnil_type
         end
       end

       # Handle Array(T) and Hash(K, V) type of arguments
       if nonnil_type.is_a?(Generic)
         if nonnil_type.name.resolve == ::Array
           mode = :sequential
           value_type = nonnil_type.type_vars.first

           # It's about to get worse!
           value_type = value_type.is_a?(Path) ? value_type.resolve : value_type
           value_types = value_type.is_a?(Generic) ? value_type.type_vars.map { |x| x.is_a?(Path) ? x.resolve : x } : [value_type]
           value_type = value_types.includes?(Nil) ? value_types.reject(&.==(Nil)).first : value_types.first
         elsif nonnil_type.name.resolve == ::Hash
           mode = :associative
           key_type = nonnil_type.type_vars.first
           value_type = nonnil_type.type_vars.last

           # Now, twice as bad
           value_type = value_type.is_a?(Path) ? value_type.resolve : value_type
           value_types = value_type.is_a?(Generic) ? value_type.type_vars.map { |x| x.is_a?(Path) ? x.resolve : x } : [value_type]
           value_type = value_types.includes?(Nil) ? value_types.reject(&.==(Nil)).first : value_types.first

           key_type = key_type.is_a?(Path) ? key_type.resolve : key_type
           key_types = key_type.is_a?(Generic) ? key_type.type_vars.map { |x| x.is_a?(Path) ? x.resolve : x } : [key_type]
           key_type = key_types.includes?(Nil) ? key_types.reject(&.==(Nil)).first : key_types.first
         elsif nonnil_type.name.resolve == ::Union
           # Do nothing, we already resolved this one above.
         else
           type.raise("Only Array or Hash are allowed as generic types")
         end
       else
         mode = :single
       end

       # Use the user defined converter, or use the default one.
       value_converter = v[:converter] || v[:value_converter] || "::Toka::Converter::#{value_type}"
       key_converter = v[:key_converter] || "::Toka::Converter::#{key_type}"

       if value_type.is_a?(Generic) && !(v[:converter] || v[:value_converter])
         value_type.raise "Unions and Generics require a custom value_converter"
       end

       if key_type && key_type.is_a?(Generic) && !v[:key_converter]
         key_type.raise "Unions and Generics require a custom key_converter"
       end

       config = { # Rewrite the configuration for internal use
         index:           opt_index,
         long_names:      long,
         all_long_names:  ([] of String + long), # Duplicate arrays
         short_names:     short,
         all_short_names: ([] of String + (short || [] of String)),
         value_name:      value_name,
         description:     v[:description],
         category:        v[:category],
         type:            nonnil_type, # type,
         mode:            mode,
         value_type:      value_type,
         key_type:        key_type,
         nilable:         nilable,
         has_default:     has_default,
         default:         default,
         key_converter:   key_converter,
         value_converter: value_converter,
         key_verifier:    v[:key_verifier],
         value_verifier:  v[:verifier] || v[:value_verifier],
       }

       opt_index = opt_index + 1
       options[k] = config %}
    {% end %}

    # Automatically choose unique short-names.
    {% for name, config in options %}
      {% if config[:short_names] == false %}
        {% config[:short_names] = [] of String %}
      {% elsif config[:short_names].empty? %}
        {% candidates = [] of String %}
        {% for name in config[:long_names] %}
          {% candidates = candidates + name.split("-").map(&.[0..0]) %}
        {% end %}
        {% for name in config[:long_names] %}
          {% candidates = candidates + name.gsub(/-/, "").split("") %}
        {% end %}

        {% found_candidates = candidates.reject { |x| short_names.includes? x }
           unless found_candidates.empty?
             short_names << found_candidates.first
             config[:short_names] = [found_candidates.first]
             config[:all_short_names] = [found_candidates.first]
           end %}
      {% end %}
    {% end %}

    # Add inversion switches for Bool options
    {% for _name, config in options %}
      {% if config[:type] == Bool %}
        {% generated_short = config[:short_names].map(&.upcase).reject{|x| short_names.includes? x }
           generated_long = config[:all_long_names].map{|x| "no-#{x.id}" }

           config[:all_short_names] = config[:all_short_names] + generated_short
           config[:all_long_names] = config[:all_long_names] + generated_long %}
      {% end %}
    {% end %}

    # Generate option getters
    {% for name, config in options %}
      {% if config[:nilable] %}
        @{{ name.stringify.id }} : {{ config[:type] }} | Nil
      {% else %}
        @{{ name.stringify.id }} : {{ config[:type] }}
      {% end %}
      # Getter for `{{ name.id }}`.
      # This option can be accessed through the long-option {{ config[:long_names].map { |x| "`--#{x.id}`" }.join(", ").id }}
      # or the short-option {{ config[:all_short_names].map { |x| "`-#{x.id}`" }.join(", ").id }}
      {% if config[:nilable] %}
        def {{name.stringify.id}} : {{config[:type]}} | Nil
          @{{name.stringify.id}}
        end
      {% else %}
        def {{name.stringify.id}} : {{config[:type]}}
          @{{name.stringify.id}}
        end
      {% end %}
      {% if config[:type] == Bool %}
        # Getter for `{{ name.stringify.id }}`.  See `#{{ name.stringify.id }}` for full documentation.
        def {{name.stringify.id}}? : Bool
          !!@{{name.stringify.id}}
        end
      {% end %}
    {% end %}

    @@toka_options = ::Toka::OptionDescriptor.new(
      banner: {{ info[:banner] || "" }},
      footer: {{ info[:footer] }},
      options: [
      {% for name, config in options %}
        ::Toka::Option.new(
          {{ name.stringify }},
          {{ config[:all_long_names] }} of String,
          {{ config[:all_short_names].map(&.chars.first) }} of Char,
          {{ config[:value_name] }},
          {{ config[:description] }},
          {{ config[:category] }},
          {{ config[:type] != Bool }}
        ),
      {% end %}
      {% if info[:help] != false %}
        ::Toka::Option.new(
          "help",
          [ "help" ],
          [ 'h' ],
          "",
          "Shows this help",
          nil,
          false,
        ),
      {% end %}
    ])

    # Descriptor of available options
    class_getter toka_options : ::Toka::OptionDescriptor
    getter positional_options = [] of String

    # Work-around compiler bug
    {% for name, config in options %}
      {% config[:short_names] = nil if config[:short_names].empty?
         config[:all_short_names] = nil if config[:all_short_names].empty?
         config[:long_names] = nil if config[:long_names].empty? %}
    {% end %}

    def initialize(strings : Indexable(String) = ARGV)
      {% for name, config in options %}
        {% if config[:mode] != :single %}
          %var_{name} = {{ config[:type].id }}.new
        {% else %}
          %var_{name} = nil.as({{ config[:type].id }} | Nil)
        {% end %}
      {% end %}

      index = 0
      while index < strings.size
        current = strings[index]
        value = nil

        if current.starts_with?("--")
          current, value = current.split("=", 2) if current.includes?('=')

          case current
          when "--" # Handle case to stop handling switches
            @positional_options.concat strings[(index + 1)..-1]
            break
          {% if info[:help] != false %}
          when "--help"
            puts ::Toka::HelpPageRenderer.new(self.class, {{ help_colors }})
            exit
          {% end %}
          {% for name, config in options %}
            {% for opt in (config[:long_names] || [] of String) %}
            when {{ "--#{opt.id}" }}
              ::Toka._read_value(%var_{name}, {{ name }}, {{ config }}, "t")
              {% if config[:value_type] == Bool %}
                when {{ "--no-#{opt.id}" }}
                  ::Toka._read_value(%var_{name}, {{ name }}, {{ config }}, "f")
              {% end %}
            {% end %}
          {% end %}
          else
            raise ::Toka::UnknownOptionError.new("Unknown option #{current.inspect}", strings, index, current)
          end
        elsif current.starts_with?("-")
          inner = 1 # Skip leading "-"
          while inner < current.size
            value = nil

            case current[inner]
            {% if info[:help] != false %}
              when 'h'
                puts ::Toka::HelpPageRenderer.new(self.class, {{ help_colors }})
                exit
            {% end %}
            {% for name, config in options %}
              {% for opt in (config[:short_names] || [] of Char) %}
              when '{{ opt.id }}'
                {% if config[:value_type] == Bool %}
                  ::Toka._read_value(%var_{name}, {{ name }}, {{ config }}, "t")
                  {% if (config[:all_short_names] || [] of Char).includes?(opt.upcase) %}
                    when '{{ opt.upcase.id }}'
                      ::Toka._read_value(%var_{name}, {{ name }}, {{ config }}, "f")
                  {% end %}
                {% else %}
                  value = current[(inner + 1)..-1] if inner + 1 < current.size
                  ::Toka._read_value(%var_{name}, {{ name }}, {{ config }}, "BUG")
                  break
                {% end %}
              {% end %}
            {% end %}
            else
              raise ::Toka::UnknownOptionError.new("Unknown option #{current[inner].inspect} in #{current.inspect}", strings, index, current[inner].to_s)
            end

            inner += 1
          end
        elsif current.starts_with? '\\'
          @positional_options << current[1..-1]
        else
          @positional_options << current
        end

        index += 1
      end

      {% for name, config in options %}
        {% if config[:has_default] %}
          {% if config[:mode] == :single %}
            @{{ name.id }} = %var_{name}.nil? ? {{ config[:default] }} : %var_{name}
          {% else %}
            @{{ name.id }} = %var_{name}.empty? ? {{ config[:default] }} : %var_{name}
          {% end %}
        {% elsif config[:nilable] %}
          @{{ name.id }} = %var_{name}
        {% else %}
          if %var_{name}.nil?
            option = @@toka_options.options[{{ config[:index] }}]
            raise ::Toka::MissingOptionError.new("Missing option #{{{ name.stringify }}.inspect}", strings, option)
          end

          @{{ name.id }} = %var_{name}
        {% end %}
      {% end %}
    end
  end
end
